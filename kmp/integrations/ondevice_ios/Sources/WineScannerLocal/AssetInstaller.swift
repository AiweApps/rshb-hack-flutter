import Foundation
import CryptoKit
import zlib

/// Installs only the exact assets manifest compiled into the app. Archive input
/// is streamed; links, extra files, traversal and oversized entries are rejected.
public enum LocalAssetInstaller {
    public static func sha256(_ file: URL, cancelled: () -> Bool = { false }) throws -> String {
        let stream = try FileHandle(forReadingFrom: file)
        defer { try? stream.close() }
        var digest = SHA256()
        while try autoreleasepool(invoking: { () throws -> Bool in
            guard let data = try stream.read(upToCount: 1024 * 1024), !data.isEmpty else { return false }
            if cancelled() { throw CancellationError() }
            digest.update(data: data)
            return true
        }) {}
        return digest.finalize().map { String(format: "%02x", $0) }.joined()
    }

    public static func install(archive: URL, staging: URL, expectedManifest: String,
                               expectedBytes: Int64, cancelled: () -> Bool,
                               progress: (Int64) -> Void) throws {
        guard !FileManager.default.fileExists(atPath: staging.path), expectedBytes > 0,
              expectedBytes < 1500 * 1024 * 1024 else { throw LocalScanError.invalidAsset("install budget") }
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        var complete = false
        defer { if !complete { try? FileManager.default.removeItem(at: staging) } }
        guard let input = gzopen(archive.path, "rb") else { throw LocalScanError.invalidAsset("archive") }
        defer { gzclose(input) }
        var consumed: Int64 = 0
        // The declared bytes cover files, with a separate bounded tar-header allowance.
        let maximum = expectedBytes + 4096 * 1024 + 10240
        func read(_ count: Int) throws -> Data {
            if cancelled() { throw CancellationError() }
            var data = Data(count: count)
            let amount = data.withUnsafeMutableBytes { gzread(input, $0.baseAddress, UInt32(count)) }
            guard amount == count else { throw LocalScanError.invalidAsset("truncated archive") }
            consumed += Int64(count)
            guard consumed <= maximum else { throw LocalScanError.invalidAsset("archive budget") }
            return data
        }
        func field(_ data: Data, _ start: Int, _ count: Int) throws -> String {
            let value = data[start..<(start + count)].prefix { $0 != 0 }
            guard let text = String(bytes: value, encoding: .utf8) else {
                throw LocalScanError.invalidAsset("archive encoding")
            }
            return text
        }
        var expected: [String: [String: Any]]?
        var orderedNames: [String] = []
        var fileIndex = 0
        var seen = Set<String>()
        var written: Int64 = 0
        while true {
            let header = try read(512)
            if header.allSatisfy({ $0 == 0 }) {
                guard try read(512).allSatisfy({ $0 == 0 }) else {
                    throw LocalScanError.invalidAsset("archive ending")
                }
                break
            }
            let name = try field(header, 0, 100), prefix = try field(header, 345, 155)
            let wireName = prefix.isEmpty ? name : prefix + "/" + name
            let relative: String
            if expected == nil {
                relative = wireName
            } else {
                guard wireName == String(format: "files/%04d", fileIndex), fileIndex < orderedNames.count else {
                    throw LocalScanError.invalidAsset("archive file order")
                }
                relative = orderedNames[fileIndex]; fileIndex += 1
            }
            let parts = relative.split(separator: "/", omittingEmptySubsequences: false)
            guard !parts.isEmpty, parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }),
                  !relative.contains("\\"), relative.utf8.count <= 255,
                  header[156] == 0 || header[156] == 48,
                  try field(header, 257, 5) == "ustar",
                  let size = Int64(try field(header, 124, 12).trimmingCharacters(in: .whitespaces), radix: 8),
                  size >= 0, size <= expectedBytes,
                  let checksum = Int(try field(header, 148, 8).trimmingCharacters(in: .whitespaces), radix: 8),
                  header.enumerated().reduce(0, { $0 + ((148..<156).contains($1.offset) ? 32 : Int($1.element)) }) == checksum,
                  seen.insert(relative).inserted else { throw LocalScanError.invalidAsset("archive entry") }
            if expected == nil {
                guard relative == "assets.json", size <= 1024 * 1024 else {
                    throw LocalScanError.invalidAsset("manifest must be first")
                }
            } else {
                guard let entry = expected?[relative], entry["bytes"] as? Int64 == size else {
                    throw LocalScanError.invalidAsset("unexpected asset: " + relative)
                }
            }
            let target = staging.appendingPathComponent(relative).standardizedFileURL
            guard target.path.hasPrefix(staging.standardizedFileURL.path + "/") else {
                throw LocalScanError.invalidAsset("archive path")
            }
            try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            guard FileManager.default.createFile(atPath: target.path, contents: nil,
                                                 attributes: [.posixPermissions: 0o600]) else {
                throw LocalScanError.invalidAsset("create asset")
            }
            let output = try FileHandle(forWritingTo: target)
            var digest = SHA256(), remaining = size
            do {
                while remaining > 0 {
                    try autoreleasepool {
                        let bytes = try read(Int(min(remaining, 1024 * 1024)))
                        try output.write(contentsOf: bytes); digest.update(data: bytes)
                        remaining -= Int64(bytes.count); written += Int64(bytes.count)
                        progress(written)
                    }
                }
                try output.close()
            } catch {
                try? output.close(); throw error
            }
            let actual = digest.finalize().map { String(format: "%02x", $0) }.joined()
            if expected == nil {
                guard actual == expectedManifest,
                      let doc = try JSONSerialization.jsonObject(with: Data(contentsOf: target)) as? [String: Any],
                      doc["kind"] as? String == "wine-ondevice-ios-candidate-assets-v1",
                      let files = doc["files"] as? [String: [String: Any]], files.count <= 4096,
                      files.values.allSatisfy({ ($0["bytes"] as? Int64 ?? -1) >= 0 }),
                      files.values.reduce(Int64(0), { $0 + ($1["bytes"] as! Int64) }) + size == expectedBytes else {
                    throw LocalScanError.invalidAsset("pinned assets manifest")
                }
                expected = files
                guard files.keys.allSatisfy({ $0.unicodeScalars.allSatisfy({ $0.value < 128 }) }) else {
                    throw LocalScanError.invalidAsset("manifest path encoding")
                }
                orderedNames = files.keys.sorted()
            } else if actual != expected?[relative]?["sha256"] as? String {
                throw LocalScanError.invalidAsset("asset checksum: " + relative)
            }
            let padding = Int((512 - size % 512) % 512)
            if padding > 0 { _ = try read(padding) }
        }
        guard let expected, seen == Set(expected.keys).union(["assets.json"]), written == expectedBytes else {
            throw LocalScanError.invalidAsset("missing assets")
        }
        // Consume the record padding and gzip trailer too; gzread validates CRC.
        var tail = [UInt8](repeating: 0, count: 512)
        var trailing = 0
        while true {
            let amount = gzread(input, &tail, UInt32(tail.count))
            if amount == 0 { break }
            guard amount > 0, trailing < 10240, tail.prefix(Int(amount)).allSatisfy({ $0 == 0 }) else {
                throw LocalScanError.invalidAsset("archive trailer")
            }
            trailing += Int(amount)
        }
        complete = true
    }
}
