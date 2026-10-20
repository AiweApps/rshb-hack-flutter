import Foundation

/// Bounded local evidence for image failures on a physical device. Never stores
/// pixels, credentials, full sandbox paths or network query parameters.
enum ImageLoadDiagnostics {
    private static let lock = NSLock()
    private static let destination = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("winescan-image-load.json")

    static func record(_ stage: String, source: String, detail: String) {
        #if DEBUG
        let name = URL(string: source)?.lastPathComponent ?? (source as NSString).lastPathComponent
        lock.lock()
        defer { lock.unlock() }
        var rows = (try? Data(contentsOf: destination)).flatMap {
            try? JSONSerialization.jsonObject(with: $0) as? [[String: Any]]
        } ?? []
        rows.append(["time": Date().timeIntervalSince1970, "stage": stage, "name": name, "detail": detail])
        rows = Array(rows.suffix(40))
        if let data = try? JSONSerialization.data(withJSONObject: rows) {
            try? data.write(to: destination, options: .atomic)
        }
        #endif
    }
}
