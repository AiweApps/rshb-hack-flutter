import Foundation
import CryptoKit
import WineScannerLocal

/// Owns downloaded model files and transport. Backend choice stays in shared Kotlin.
final class LocalScannerAssetStore: NSObject, URLSessionDownloadDelegate {
    static let storageDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("LocalScannerAssets", isDirectory: true)
    private let lock = NSLock()
    private let pin: String
    private let archiveSize: Int64
    private let manifestPath: String
    private var ready: URL?
    private var observer: ((String) -> Void)?
    private var phase = "not_installed"
    private var received: Int64 = 0
    private var total: Int64 = 0
    private var failure: String?
    private var generation: String?
    private var descriptor: Descriptor?
    private var prepare: Task<Void, Never>?
    private var transfer: URLSessionDownloadTask?
    private var lastEmission = Date.distantPast

    private struct Descriptor {
        let archiveSHA: String
        let archiveBytes: Int64
        let unpackedBytes: Int64
        let url: URL
    }

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 3600
        configuration.httpMaximumConnectionsPerHost = 2
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    override init() {
        let metadata = Bundle.main.url(forResource: "LocalScannerDownload", withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        pin = metadata?["assets_manifest_sha256"] as? String ?? "fec6732df669b2184a612a479df46672c8767e70d2c496361f21d7de47582f65"
        archiveSize = metadata?["archive_bytes"] as? Int64 ?? 0
        manifestPath = metadata?["manifest_path"] as? String ?? "/api/local-scanner/manifest.json"
        super.init()
        let candidates = [Self.storageDirectory.appendingPathComponent(pin, isDirectory: true),
                          Bundle.main.bundleURL.appendingPathComponent("LocalScannerAssets", isDirectory: true)]
        ready = candidates.first { directory in
            guard let data = try? Data(contentsOf: directory.appendingPathComponent("assets.json")),
                  SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == pin else { return false }
            return ["cards.json", "WineEncoderB0.mlpackage", "WineEncoderE.mlpackage",
                    "WineDetectorbottle.mlpackage", "WineDetectorlabel.mlpackage", "WineDetectorlabel_rescue.mlpackage", "WineDetectorlabel_fullframe.mlpackage"]
                .allSatisfy { FileManager.default.fileExists(atPath: directory.appendingPathComponent($0).path) }
        }
        if ready != nil { phase = "ready" }
        total = archiveSize
        for url in (try? FileManager.default.contentsOfDirectory(at: Self.storageDirectory, includingPropertiesForKeys: nil)) ?? []
            where url.lastPathComponent.hasPrefix(".install-") {
            try? FileManager.default.removeItem(at: url)
        }
        let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        for url in (try? FileManager.default.contentsOfDirectory(at: cache, includingPropertiesForKeys: nil)) ?? []
            where url.lastPathComponent.hasPrefix("wine-local-model-download-") {
            try? FileManager.default.removeItem(at: url)
        }
    }

    var directory: URL? { lock.lock(); defer { lock.unlock() }; return ready }

    func stateJson() -> String {
        lock.lock(); defer { lock.unlock() }
        return jsonLocked()
    }

    func observe(_ callback: @escaping (String) -> Void) {
        lock.lock(); observer = callback; let value = jsonLocked(); lock.unlock()
        callback(value)
    }

    private func jsonLocked() -> String {
        var state: [String: Any] = ["phase": phase, "received_bytes": received,
                                   "total_bytes": total, "available": ready != nil]
        if let failure { state["error"] = failure }
        return String(data: try! JSONSerialization.data(withJSONObject: state), encoding: .utf8)!
    }

    private func update(_ id: String, phase: String, bytes: Int64 = 0, total: Int64? = nil,
                        error: String? = nil, directory: URL? = nil) {
        lock.lock()
        guard generation == id else { lock.unlock(); return }
        let changed = self.phase != phase
        self.phase = phase; received = bytes; failure = error
        if let total { self.total = total }
        if let directory { ready = directory }
        let emit = changed || Date().timeIntervalSince(lastEmission) >= 0.2
        if emit { lastEmission = Date() }
        let callback = observer, value = emit ? jsonLocked() : nil
        lock.unlock()
        if let value { callback?(value) }
    }

    private func isCurrent(_ id: String) -> Bool {
        lock.lock(); defer { lock.unlock() }; return generation == id
    }

    func download(baseURL: String, token: String) {
        lock.lock()
        guard ready == nil, generation == nil else { lock.unlock(); return }
        let id = UUID().uuidString; generation = id; lock.unlock()
        update(id, phase: "preparing", total: archiveSize)
        prepare = Task { [weak self] in
            guard let self else { return }
            do {
                guard let origin = URL(string: baseURL), origin.scheme == "https",
                      origin.host == "wines.aiweapps.com" || origin.host == "vines.aiweapps.com",
                      !token.isEmpty else { throw URLError(.userAuthenticationRequired) }
                guard manifestPath == "/api/local-scanner/manifest.json" ||
                      manifestPath == "/api/local-scanner/manifests/\(pin).json" else { throw LocalScanError.invalidAsset("manifest address") }
                var request = URLRequest(url: origin.appendingPathComponent(manifestPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))))
                request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
                let (data, response) = try await session.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200, data.count < 65536,
                      let doc = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      doc["kind"] as? String == "wine-ondevice-download-v1",
                      doc["archive_format"] as? String == "manifest-indexed-ustar-gzip-v1",
                      doc["assets_manifest_sha256"] as? String == pin,
                      let sha = doc["archive_sha256"] as? String, sha.count == 64,
                      sha.allSatisfy({ "0123456789abcdef".contains($0) }),
                      let count = doc["archive_bytes"] as? Int64, count > 0, count < 2 * 1024 * 1024 * 1024,
                      let unpacked = doc["unpacked_bytes"] as? Int64, unpacked > 0, unpacked < 1500 * 1024 * 1024,
                      let path = doc["archive_path"] as? String, path == "/api/local-scanner/package-\(sha).tar.gz",
                      let address = URL(string: path, relativeTo: origin)?.absoluteURL else {
                    throw LocalScanError.invalidAsset("download descriptor")
                }
                try FileManager.default.createDirectory(at: Self.storageDirectory, withIntermediateDirectories: true)
                let capacity = try Self.storageDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                    .volumeAvailableCapacityForImportantUsage
                if let capacity, capacity < count + unpacked + 256 * 1024 * 1024 {
                    throw CocoaError(.fileWriteOutOfSpace)
                }
                guard isCurrent(id), !Task.isCancelled else { throw CancellationError() }
                let description = Descriptor(archiveSHA: sha, archiveBytes: count, unpackedBytes: unpacked, url: address)
                var downloadRequest = URLRequest(url: address)
                downloadRequest.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
                let task = session.downloadTask(with: downloadRequest); task.taskDescription = id
                let accepted = lock.withLock { () -> Bool in
                    guard self.generation == id else { return false }
                    self.descriptor = description; self.transfer = task; return true
                }
                guard accepted else { task.cancel(); return }
                update(id, phase: "downloading", total: count)
                task.resume()
            } catch { finishError(id, error) }
        }
    }

    func cancel() {
        lock.lock()
        generation = nil; let task = transfer; transfer = nil
        let pending = prepare; prepare = nil; descriptor = nil
        phase = ready == nil ? "not_installed" : "ready"; received = 0; total = archiveSize; failure = nil
        let callback = observer, value = jsonLocked(); lock.unlock()
        task?.cancel(); pending?.cancel(); callback?(value)
    }

    private func finishError(_ id: String, _ error: Error) {
        let code: String
        if error is CancellationError || (error as NSError).code == NSURLErrorCancelled { code = "cancelled" }
        else if (error as NSError).domain == NSCocoaErrorDomain && (error as NSError).code == NSFileWriteOutOfSpaceError { code = "storage_full" }
        else if error is LocalScanError { code = "verification_failed" }
        else { code = "download_failed" }
        update(id, phase: code == "cancelled" ? "not_installed" : "failed", error: code)
        lock.lock(); if generation == id { generation = nil; transfer = nil; descriptor = nil; prepare = nil }; lock.unlock()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let id = downloadTask.taskDescription else { return }
        lock.lock(); let limit = descriptor?.archiveBytes; lock.unlock()
        if let limit, totalBytesWritten > limit {
            downloadTask.cancel(); finishError(id, LocalScanError.invalidAsset("download byte limit")); return
        }
        update(id, phase: "downloading", bytes: totalBytesWritten)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let id = task.taskDescription, let error { finishError(id, error) }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        let allowed = request.url?.scheme == "https" && request.url?.host == task.originalRequest?.url?.host
        completionHandler(allowed ? request : nil)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let id = downloadTask.taskDescription else { return }
        lock.lock(); let description = descriptor, active = generation == id; lock.unlock()
        guard active, let description else { return }
        let archive = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("wine-local-model-download-\(id).tar.gz")
        do {
            guard (downloadTask.response as? HTTPURLResponse)?.statusCode == 200,
                  (try location.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) == description.archiveBytes else {
                throw URLError(.badServerResponse)
            }
            try FileManager.default.moveItem(at: location, to: archive)
        } catch { finishError(id, error); return }
        Task.detached(priority: .utility) { [self] in
            let staging = Self.storageDirectory.appendingPathComponent(".install-" + id, isDirectory: true)
            defer { try? FileManager.default.removeItem(at: archive); try? FileManager.default.removeItem(at: staging) }
            do {
                update(id, phase: "verifying", total: description.unpackedBytes)
                guard try LocalAssetInstaller.sha256(archive, cancelled: { !self.isCurrent(id) }) == description.archiveSHA else {
                    throw LocalScanError.invalidAsset("archive checksum")
                }
                try LocalAssetInstaller.install(archive: archive, staging: staging, expectedManifest: pin,
                    expectedBytes: description.unpackedBytes, cancelled: { !self.isCurrent(id) },
                    progress: { self.update(id, phase: "installing", bytes: $0, total: description.unpackedBytes) })
                let destination = Self.storageDirectory.appendingPathComponent(pin, isDirectory: true)
                var values = URLResourceValues(); values.isExcludedFromBackup = true
                var folder = staging; try folder.setResourceValues(values)
                try lock.withLock {
                    guard generation == id else { throw CancellationError() }
                    // Only this app-owned version slot can be replaced; scans/history are elsewhere.
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    try FileManager.default.moveItem(at: staging, to: destination)
                    ready = destination
                }
                update(id, phase: "ready", bytes: description.archiveBytes, total: description.archiveBytes, directory: destination)
                lock.withLock { if generation == id { generation = nil; transfer = nil; descriptor = nil; prepare = nil } }
            } catch { finishError(id, error) }
        }
    }
}
