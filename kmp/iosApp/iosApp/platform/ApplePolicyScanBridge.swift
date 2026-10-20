import Foundation
import CryptoKit
import WineScannerLocal

/// App-side interpreter owner. Models, GIL and original rules execute serially.
/// The shared ScanResult component remains the owner of cancellation and storage.
final class ApplePolicyScanBridge {
    private static let workLock = NSLock()
    private static var initializedRoot: String?
    private let directory: URL
    private var verified = false

    init(directory: URL) { self.directory = directory }

    func recognize(photoPath: String, roiJson: String?, progress: @escaping @Sendable (String) -> Void) async throws -> String {
        let folder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LocalPolicyRequests/" + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let poll = Task.detached(priority: .utility) {
            var previous: Data?
            while !Task.isCancelled {
                if let data = try? Data(contentsOf: folder.appendingPathComponent("geometry.json")), data != previous,
                   let text = String(data: data, encoding: .utf8), !Task.isCancelled {
                    previous = data; progress(text)
                }
                do { try await Task.sleep(for: .milliseconds(100)) } catch { break }
            }
        }
        defer { poll.cancel(); try? FileManager.default.removeItem(at: folder) }
        let worker = Task.detached(priority: .userInitiated) { [self] in
            try Self.workLock.withLock {
                try Task.checkCancellation()
                try verifyAssets()
                let bundle = Bundle.main.bundleURL, code = bundle.appendingPathComponent("LocalScannerPolicy").path
                try Self.initialize(bundle: bundle, code: code)
                // Allocate models only after acquiring the shared owner lock.
                let model = try NativeInference(modelDirectory: directory, names: ["WineEncoderB0", "WineEncoderE",
                    "WineDetectorbottle", "WineDetectorlabel", "WineDetectorlabel_rescue", "WineDetectorlabel_fullframe"])
                let arguments: [Any] = [code, photoPath, roiJson ?? "null", folder.path,
                    NativePolicyBridge.callAddress, NativePolicyBridge.freeAddress]
                let literal = try JSONSerialization.data(withJSONObject: arguments).base64EncodedString()
                _ = try NativePolicyBridge.withRequest(model: model) {
                    let gil = PyGILState_Ensure(); defer { PyGILState_Release(gil) }
                    let script = """
                    import base64, json, traceback
                    from pathlib import Path
                    arguments = json.loads(base64.b64decode('\(literal)'))
                    try:
                        from application import run
                        run(*arguments)
                    except Exception as error:
                        (Path(arguments[3]) / 'outcome.json').write_text(json.dumps(
                            {'ok': False, 'error': str(error), 'traceback': traceback.format_exc()}, ensure_ascii=False))
                    """
                    guard script.withCString({ PyRun_SimpleStringFlags($0, nil) }) == 0 else {
                        throw LocalScanError.invalidAsset("Python policy entrypoint")
                    }
                }
                try Task.checkCancellation()
                let result = try JSONSerialization.jsonObject(with: Data(contentsOf: folder.appendingPathComponent("outcome.json"))) as? [String: Any]
                guard let result, result["ok"] as? Bool == true, result["HTTP"] as? Int == 0,
                      result["outer_request_wrappers_complete"] as? Bool == true,
                      let view = result["view"] as? [String: Any] else {
                    #if DEBUG
                    // Keep the short cause separate: unified logging may truncate
                    // a full original-policy traceback before its final exception.
                    NSLog("WineScan local pipeline error: %@", result?["error"] as? String ?? "Invalid local result")
                    NSLog("WineScan local pipeline: %@", result?["traceback"] as? String ?? "Invalid local result")
                    #endif
                    throw LocalScanError.invalidAsset("Full local policy failed")
                }
                let data = try JSONSerialization.data(withJSONObject: view)
                guard let answer = String(data: data, encoding: .utf8) else { throw LocalScanError.invalidModelOutput }
                return answer
            }
        }
        return try await withTaskCancellationHandler(operation: { try await worker.value }, onCancel: {
            worker.cancel(); poll.cancel()
        })
    }

    func releaseModels() {
        Task.detached(priority: .utility) {
            Self.workLock.withLock {
                guard Self.initializedRoot != nil else { return }
                let gil = PyGILState_Ensure(); defer { PyGILState_Release(gil) }
                _ = "from application import release; release()".withCString { PyRun_SimpleStringFlags($0, nil) }
            }
        }
    }

    private static func initialize(bundle: URL, code: String) throws {
        if let initializedRoot {
            guard initializedRoot == code else { throw LocalScanError.invalidAsset("Policy update requires restart") }
            return
        }
        setenv("PYTHONHOME", bundle.appendingPathComponent("python").path, 1)
        setenv("PYTHONPATH", code + ":" + bundle.appendingPathComponent("app_packages").path, 1)
        setenv("PYTHONDONTWRITEBYTECODE", "1", 1); setenv("PYTHONUTF8", "1", 1)
        setenv("WINE_POLICY_DATA_ROOT", code, 1); setenv("WINE_CONTROL_DATA_ROOT", code, 1)
        setenv("WINE_GEOMETRY_LIBRARY", bundle.appendingPathComponent("Frameworks/WineGeometry.framework/WineGeometry").path, 1)
        setenv("OPENBLAS_NUM_THREADS", "1", 1); setenv("OMP_NUM_THREADS", "1", 1)
        var config = PyPreConfig(); PyPreConfig_InitPythonConfig(&config); config.utf8_mode = 1
        guard PyStatus_Exception(Py_PreInitialize(&config)) == 0 else { throw LocalScanError.invalidAsset("Python preinit") }
        Py_Initialize(); _ = PyEval_SaveThread(); initializedRoot = code
    }

    private func verifyAssets() throws {
        if verified { return }
        let bundle = Bundle.main.bundleURL
        let policy = try JSONSerialization.jsonObject(with: Data(contentsOf: bundle.appendingPathComponent("LocalScannerPolicy/policy-manifest.json"))) as? [String: Any]
        let bytes = try Data(contentsOf: directory.appendingPathComponent("assets.json"))
        let hash = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        guard policy?["native_assets_sha256"] as? String == hash,
              let manifest = try JSONSerialization.jsonObject(with: bytes) as? [String: Any],
              let files = manifest["files"] as? [String: [String: Any]] else { throw LocalScanError.invalidAsset("Policy/model binding") }
        for (name, pin) in files {
            try Task.checkCancellation()
            let path = directory.appendingPathComponent(name).standardizedFileURL
            guard !name.contains(".."), path.path.hasPrefix(directory.standardizedFileURL.path + "/") else { throw LocalScanError.invalidAsset(name) }
            try autoreleasepool {
                let data = try Data(contentsOf: path, options: .mappedIfSafe)
                guard data.count == pin["bytes"] as? Int,
                      SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == pin["sha256"] as? String
                else { throw LocalScanError.invalidAsset(name) }
            }
        }
        verified = true
    }
}
