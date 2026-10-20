import Foundation
import CryptoKit
import SharedLogic
import WineScannerLocal

/// Native transport for the shared scanner owner. It never calls the scanner API.
final class AppleLocalScanEngine: LocalScanEngine {
    private let assets = LocalScannerAssetStore()
    private var scanner: ApplePolicyScanBridge?
    private var scannerDirectory: URL?
    private var directory: URL { assets.directory ?? LocalScannerAssetStore.storageDirectory.appendingPathComponent("not-installed") }
    private let lock = NSLock()
    private final class Request {
        var task: Task<Void, Never>?
        var cancelled = false
    }
    private var requests: [String: Request] = [:]
    private var catalogue: [String: [String: Any]]?
    private var searchable = Set<String>()

    func isAvailable() -> Bool { assets.directory != nil }
    func assetsStateJson() -> String { assets.stateJson() }
    func observeAssetsState(observer: @escaping (String) -> Void) { assets.observe(observer) }
    func downloadAssets(baseUrl: String, token: String) { assets.download(baseURL: baseUrl, token: token) }
    func cancelAssetDownload() { assets.cancel() }

    private func loadedScanner() throws -> ApplePolicyScanBridge {
        guard let directory = assets.directory else { throw LocalScanError.invalidAsset("models not installed") }
        return lock.withLock {
            if let scanner, scannerDirectory == directory { return scanner }
            let created = ApplePolicyScanBridge(directory: directory)
            scanner = created; scannerDirectory = directory
            return created
        }
    }

    func statusJson() -> String {
        let ready = isAvailable()
        let status: [String: Any] = ["backend_reachable": ready, "profile_match": ready, "ready": ready,
            "runtime_descriptor": "ondevice-ios-full-policy-v1", "catalog": ["cards": 2266]]
        return String(data: try! JSONSerialization.data(withJSONObject: status), encoding: .utf8)!
    }

    func referenceBaseUrl() -> String { directory.absoluteString }

    func wineJson(slug: String) -> String? {
        guard let card = loadCatalogue()?[slug], let data = try? JSONSerialization.data(withJSONObject: card) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func searchJson(query: String) -> String {
        let terms = query.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).prefix(12).map(String.init)
        guard !terms.isEmpty, let catalogue = loadCatalogue() else { return "[]" }
        let rows = catalogue.values.filter { card in
            guard let slug = card["slug"] as? String, searchable.contains(slug) else { return false }
            let haystack = ["title", "producer", "grapes", "region"].compactMap { card[$0] as? String }.joined(separator: " ").lowercased()
            return terms.allSatisfy { haystack.contains($0) }
        }.sorted { ($0["slug"] as? String ?? "") < ($1["slug"] as? String ?? "") }.prefix(20)
        guard let data = try? JSONSerialization.data(withJSONObject: Array(rows)) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private func loadCatalogue() -> [String: [String: Any]]? {
        lock.withLock {
            if let catalogue { return catalogue }
            guard let data = try? Data(contentsOf: directory.appendingPathComponent("cards.json")),
                  let manifestData = try? Data(contentsOf: directory.appendingPathComponent("assets.json")),
                  let manifest = try? JSONSerialization.jsonObject(with: manifestData) as? [String: Any],
                  let files = manifest["files"] as? [String: [String: Any]],
                  let expected = files["cards.json"]?["sha256"] as? String,
                  SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == expected,
                  let searchableData = try? Data(contentsOf: directory.appendingPathComponent("searchable-slugs.json")),
                  let searchableSHA = files["searchable-slugs.json"]?["sha256"] as? String,
                  SHA256.hash(data: searchableData).map({ String(format: "%02x", $0) }).joined() == searchableSHA,
                  let searchSlugs = try? JSONSerialization.jsonObject(with: searchableData) as? [String],
                  let rows = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else { return nil }
            searchable = Set(searchSlugs)
            catalogue = rows
            return rows
        }
    }

    func recognize(requestId: String, photoPath: String, roiJson: String?, completion: @escaping (String?, String?) -> Void) {
        recognizeWithProgress(requestId: requestId, photoPath: photoPath, roiJson: roiJson, progress: { _ in }, completion: completion)
    }

    func recognizeWithProgress(requestId: String, photoPath: String, roiJson: String?,
                               progress: @escaping (String) -> Void, completion: @escaping (String?, String?) -> Void) {
        let request = Request()
        lock.withLock { requests[requestId] = request }
        let task = Task.detached(priority: .userInitiated) { [self] in
            do {
                try Task.checkCancellation()
                let url = URL(fileURLWithPath: photoPath).standardizedFileURL
                guard url.path.hasPrefix(NSHomeDirectory() + "/") else { throw LocalScanError.invalidImage }
                let scanner = try loadedScanner()
                let answer = try await scanner.recognize(photoPath: url.path, roiJson: roiJson, progress: { [self] body in
                    let deliver = lock.withLock { requests[requestId].map { !$0.cancelled } ?? false }
                    if deliver { progress(body) }
                })
                try Task.checkCancellation()
                let deliver = lock.withLock { requests.removeValue(forKey: requestId) != nil }
                if deliver { completion(answer, nil) }
            } catch {
                let deliver = lock.withLock { requests.removeValue(forKey: requestId) != nil }
                if deliver { completion(nil, error is CancellationError ? "cancelled" : "local_recognition_failed") }
            }
        }
        lock.withLock {
            if let active = requests[requestId] { active.task = task; if active.cancelled { task.cancel() } }
        }
    }

    func cancel(requestId: String) {
        lock.withLock { requests[requestId]?.cancelled = true; requests[requestId]?.task?.cancel() }
    }

    func releaseModels() {
        let current = lock.withLock { scanner }
        current?.releaseModels()
    }
}
