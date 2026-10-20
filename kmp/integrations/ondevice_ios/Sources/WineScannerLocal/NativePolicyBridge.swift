import Foundation
import CryptoKit

/// One request owns the native models while original Python rules call them.
/// The C ABI carries RGB bytes and real model outputs, without an HTTP boundary.
public enum NativePolicyBridge {
    private static let lock = NSLock()
    private static let callLock = NSLock()
    private static var owner: NativeInference?
    private static var deadline = 0.0
    private static var allocated = Set<UInt>()
    private static var audit: [[String: Any]] = []

    public static var callAddress: UInt64 {
        typealias Call = @convention(c) (UnsafePointer<UInt8>?, Int32, Int32, Int32) -> UnsafeMutablePointer<CChar>?
        return UInt64(UInt(bitPattern: unsafeBitCast(wineNativeCallV1 as Call, to: UnsafeRawPointer.self)))
    }

    public static var freeAddress: UInt64 {
        typealias Free = @convention(c) (UnsafeMutableRawPointer?) -> Void
        return UInt64(UInt(bitPattern: unsafeBitCast(wineNativeFreeV1 as Free, to: UnsafeRawPointer.self)))
    }

    public static func withRequest<T>(model: NativeInference, _ body: () throws -> T) throws -> (T, [[String: Any]]) {
        try lock.withLock {
            guard owner == nil, allocated.isEmpty else { throw LocalScanError.invalidAsset("Another native policy request owns models") }
            owner = model;deadline = ProcessInfo.processInfo.systemUptime + 180;audit = []
        }
        model.beginRequest()
        defer {
            lock.withLock {
                owner = nil
                for address in allocated { free(UnsafeMutableRawPointer(bitPattern: address)) }
                allocated.removeAll()
            }
        }
        let result = try body()
        let records = try lock.withLock { () throws -> [[String: Any]] in
            guard allocated.isEmpty else { throw LocalScanError.invalidAsset("Native callback output was not released") }
            return audit
        }
        return (result, records)
    }

    fileprivate static func invoke(rgb: UnsafePointer<UInt8>?, width: Int32, height: Int32, operation: Int32) -> UnsafeMutablePointer<CChar>? {
        callLock.lock();defer { callLock.unlock() }
        var response: [String: Any]
        do {
            try Task.checkCancellation()
            let model = try lock.withLock { () throws -> NativeInference in
                guard let owner, ProcessInfo.processInfo.systemUptime <= deadline, audit.count < 256 else {
                    throw LocalScanError.requestBudgetExceeded
                }
                return owner
            }
            let w = Int(width), h = Int(height)
            let maximumPixels = operation == 2 ? 96_000_000 : 24_000_000
            guard let rgb, w > 0, h > 0, w <= maximumPixels / h else { throw LocalScanError.invalidImage }
            let image = try PixelImage(width: w, height: h,
                rgb: Array(UnsafeBufferPointer(start: rgb, count: w * h * 3)), maximumPixels: maximumPixels)
            let hash = SHA256.hash(data: Data(image.rgb)).map { String(format: "%02x", $0) }.joined()
            let started = ProcessInfo.processInfo.systemUptime
            let output: Any
            switch operation {
            case 0, 1:
                output = try model.bottles(image, threshold: operation == 0 ? 0.4 : 0.2).map {
                    ["bbox": $0.box, "score": $0.score] as [String: Any]
                }
            case 2, 3, 7:
                output = try model.labels(image, rescue: operation == 3, fullframe: operation == 7).map {
                    ["bbox": $0.box, "detector_score": $0.score] as [String: Any]
                }
            case 4, 5:
                guard w == 384, h == 384 else { throw LocalScanError.invalidAsset("Python owns encoder RGB384 preparation") }
                let (square, _, _, _, _) = try image.padded(side: 384, method: .bicubic, encoderCentering: true)
                guard square.rgb == image.rgb else { throw LocalScanError.invalidAsset("RGB384 native encoder preparation changed pixels") }
                output = try model.encode(image, arm: operation == 4 ? "B0" : "E")
            case 6:
                output = try JSONSerialization.jsonObject(with: JSONEncoder().encode(NativeInference.readText(image)))
            default: throw LocalScanError.invalidAsset("Unknown native operation")
            }
            let record: [String: Any] = ["operation": operation, "size": [w, h], "rgb_sha256": hash,
                "elapsed_seconds": ProcessInfo.processInfo.systemUptime - started]
            lock.withLock { audit.append(record) }
            response = ["ok": true, "operation": operation, "size": [w, h], "rgb_sha256": hash, "output": output]
        } catch { response = ["ok": false, "error": String(describing: error)] }
        guard let data = try? JSONSerialization.data(withJSONObject: response, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8), let pointer = strdup(text) else { return nil }
        lock.withLock { _ = allocated.insert(UInt(bitPattern: pointer)) }
        return pointer
    }

    fileprivate static func release(_ pointer: UnsafeMutableRawPointer?) {
        guard let pointer else { return }
        let present = lock.withLock { allocated.remove(UInt(bitPattern: pointer)) != nil }
        if present { free(pointer) }
    }
}

@_cdecl("wine_native_call_v1")
public func wineNativeCallV1(_ rgb: UnsafePointer<UInt8>?, _ width: Int32, _ height: Int32,
                             _ operation: Int32) -> UnsafeMutablePointer<CChar>? {
    NativePolicyBridge.invoke(rgb: rgb, width: width, height: height, operation: operation)
}

@_cdecl("wine_native_free_v1")
public func wineNativeFreeV1(_ pointer: UnsafeMutableRawPointer?) {
    NativePolicyBridge.release(pointer)
}
