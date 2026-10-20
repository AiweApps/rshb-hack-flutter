import Foundation
import CryptoKit

/// Native migration candidate. The profile explicitly distinguishes it from server P4.
/// No URLSession, HTTP fallback, photo upload or LLM is part of this actor.
public actor LocalScanner {
    private let directory: URL
    private var inference: NativeInference?
    private var references: [[String: String]] = []
    private var vectors: [Float] = []
    private var cards: [String: [String: Any]] = [:]
    private var head: [String: Any] = [:]
    private var gate: [String: Any] = [:]
    private var fingerprint = ""

    public init(directory: URL) { self.directory = directory }

    public func releaseModels() {
        inference = nil
    }

    private func load() throws -> NativeInference {
        if let inference { return inference }
        let manifest = try Data(contentsOf: directory.appendingPathComponent("assets.json"))
        let entries = (try JSONSerialization.jsonObject(with: manifest) as! [String: Any])["files"] as! [String: [String: Any]]
        for (relative, pin) in entries {
            try Task.checkCancellation()
            let url = directory.appendingPathComponent(relative).standardizedFileURL
            guard url.path.hasPrefix(directory.standardizedFileURL.path + "/"), !relative.contains("..") else { throw LocalScanError.invalidAsset(relative) }
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let actual = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            guard actual == pin["sha256"] as? String, data.count == pin["bytes"] as? Int else { throw LocalScanError.invalidAsset(relative) }
        }
        func json(_ name: String) throws -> Any { try JSONSerialization.jsonObject(with: Data(contentsOf: directory.appendingPathComponent(name))) }
        references = try json("references.json") as! [[String: String]]
        cards = try json("cards.json") as! [String: [String: Any]]
        head = try json("head.json") as! [String: Any]
        gate = try json("object-gate.json") as! [String: Any]
        let data = try Data(contentsOf: directory.appendingPathComponent("vectors-f32.bin"))
        vectors = data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
        guard references.count == 4474, vectors.count == 4474 * 768, vectors.allSatisfy({ $0.isFinite }) else { throw LocalScanError.invalidAsset("E4474 vectors") }
        fingerprint = "ondevice-ios-migration-v1:" + SHA256.hash(data: manifest).map { String(format: "%02x", $0) }.joined()
        let loaded = try NativeInference(modelDirectory: directory, names: ["WineEncoderB0", "WineEncoderE", "WineDetectorbottle", "WineDetectorlabel", "WineDetectorlabel_rescue"])
        inference = loaded
        return loaded
    }

    private struct Target {
        var context: [Double]
        var label: [Double]
        var physical: Bool
        var angle: Int
        var score: Float
    }

    private struct PreviewRegion {
        var bottle: [Double]?
        var label: [Double]?
    }

    private func locate(_ image: PixelImage, model: NativeInference, threshold: Float,
                        progress: ([PreviewRegion], String) -> Void) throws -> [Target] {
        let bottles = try model.bottles(image, threshold: threshold)
        let frame = [0.0, 0.0, Double(image.width), Double(image.height)]
        if bottles.isEmpty {
            let labels = try model.labels(image)
            progress(labels.map { PreviewRegion(bottle: nil, label: $0.box) }, "labels")
            return labels.map { Target(context: frame, label: $0.box, physical: false, angle: 0, score: $0.score) }
        }
        // A crowded image is not silently reduced to the first16 physical bottles.
        guard bottles.count <= 16 else { return [] }
        var preview = bottles.map { PreviewRegion(bottle: $0.box, label: nil) }
        progress(preview, "bottles")
        var targets: [Target] = []
        for (bottleIndex, bottle) in bottles.enumerated() {
            try Task.checkCancellation()
            let context = [floor(bottle.box[0]), floor(bottle.box[1]), ceil(bottle.box[2]), ceil(bottle.box[3])]
            let crop = try image.cropped(context)
            var found = try model.labels(crop), angle = 0
            if found.isEmpty, Double(crop.width) > 1.25 * Double(crop.height) {
                let a = try model.labels(crop.rotatedCCW(90)), b = try model.labels(crop.rotatedCCW(270))
                if (a.map(\.score).max() ?? -1) >= (b.map(\.score).max() ?? -1) { found = a; angle = 90 }
                else { found = b; angle = 270 }
                found = found.map { row in
                    let p = row.box
                    let box = angle == 90 ? [Double(crop.width) - p[3], p[0], Double(crop.width) - p[1], p[2]] : [p[1], Double(crop.height) - p[2], p[3], Double(crop.height) - p[0]]
                    return Detection(box: box, score: row.score)
                }
            }
            if found.isEmpty { found = try model.labels(crop, rescue: true); angle = 0 }
            guard !found.isEmpty else { continue }
            let label = [found.map { $0.box[0] }.min()! + context[0], found.map { $0.box[1] }.min()! + context[1],
                         found.map { $0.box[2] }.max()! + context[0], found.map { $0.box[3] }.max()! + context[1]]
            preview[bottleIndex].label = label
            progress(preview, "labels")
            targets.append(Target(context: context, label: label, physical: true, angle: angle, score: found.map(\.score).max()!))
        }
        return targets
    }

    private func adapt(_ feature: [Float]) -> [Float] {
        let centers = head["centers"] as! [[Double]], radii = head["radii"] as! [Double], coefficients = head["coefficients"] as! [[Double]]
        var output = feature.map(Double.init), active = false
        for k in 0..<6 {
            let distance2 = zip(feature, centers[k]).reduce(0.0) { $0 + pow(Double($1.0) - $1.1, 2) }
            let weight = max(0, 1 - distance2 / (radii[k] * radii[k]))
            if weight > 0 {
                active = true
                for j in 0..<768 { output[j] += weight * weight * coefficients[k][j] }
            }
        }
        if !active { return feature }
        let norm = sqrt(output.reduce(0.0) { $0 + $1 * $1 })
        return output.map { Float($0 / norm) }
    }

    private func rank(context: [Float], label: [Float]) -> [String] {
        var channels: [String: [String: Float]] = ["context": [:], "front_label": [:]]
        for row in references.indices {
            let kind = references[row]["kind"]!, slug = references[row]["slug"]!
            if references[row]["excluded"] == "true" { continue }
            let feature = kind == "front_label" ? label : context
            var score: Float = 0
            for j in 0..<768 { score += vectors[row * 768 + j] * feature[j] }
            if score > (channels[kind]?[slug] ?? -.infinity) { channels[kind]?[slug] = score }
        }
        func top(_ kind: String) -> [String] { channels[kind]!.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }.prefix(20).map(\.key) }
        let pool = Set(top("front_label") + top("context")), primary = channels["front_label"]!
        return pool.sorted {
            let a = primary[$0] ?? -.infinity, b = primary[$1] ?? -.infinity
            return a == b ? $0 < $1 : a > b
        }
    }

    public func recognize(data: Data, roi: [Double]?, policyEvidence: (@Sendable (String) -> Void)? = nil,
                          progress: (@Sendable (String) -> Void)? = nil) throws -> String {
        let started = Date(), image = try PixelImage(data: data), model = try load()
        model.beginRequest()
        func report(_ regions: [PreviewRegion], _ stage: String) {
            guard let progress, !Task.isCancelled else { return }
            func box(_ values: [Double]?) -> Any {
                guard let v = values else { return NSNull() }
                return ["x1": v[0], "y1": v[1], "x2": v[2], "y2": v[3]]
            }
            let packet: [String: Any] = ["stage": stage, "frame_size": [image.width, image.height],
                "regions": regions.enumerated().map { index, region in
                    ["id": "local-\(index)", "number": index + 1,
                     "bottle_box": box(region.bottle), "label_box": box(region.label)] as [String: Any]
                }]
            if let bytes = try? JSONSerialization.data(withJSONObject: packet), let text = String(data: bytes, encoding: .utf8) { progress(text) }
        }
        if let roi { _ = try image.cropped(roi) }
        func accepted(_ targets: [Target]) throws -> [(Target, [Float])] {
            var kept: [(Target, [Float])] = []
            let coefficients = gate["coef"] as! [Double], bias = gate["intercept"] as! Double, threshold = gate["threshold"] as! Double
            for target in targets {
                try Task.checkCancellation()
                let feature = try model.encode(image.cropped(target.context), arm: "B0")
                let value = zip(feature, coefficients).reduce(bias) { $0 + Double($1.0) * $1.1 }
                if 1 / (1 + exp(-min(40, max(-40, value)))) >= threshold { kept.append((target, feature)) }
            }
            return kept
        }
        func selected(_ targets: [Target]) -> [Target] {
            guard let roi else { return targets }
            let grouped = Dictionary(grouping: targets, by: { $0.context.map(String.init(describing:)).joined(separator: ",") })
            let order = grouped.values.sorted { NativeInference.overlap($0[0].context, roi) > NativeInference.overlap($1[0].context, roi) }
            guard let first = order.first, NativeInference.overlap(first[0].context, roi) > 0 else { return [] }
            if order.count > 1, abs(NativeInference.overlap(first[0].context, roi) - NativeInference.overlap(order[1][0].context, roi)) <= 1e-12 { return [] }
            return first
        }
        var targets = try accepted(selected(locate(image, model: model, threshold: 0.4, progress: report)))
        if targets.isEmpty, roi == nil { targets = try accepted(locate(image, model: model, threshold: 0.2, progress: report)) }
        report(targets.map { PreviewRegion(bottle: $0.0.physical ? $0.0.context : nil, label: $0.0.label) }, "recognition")
        var output: [[String: Any]] = []
        var nativeEvidence: [[String: Any]] = []
        for (index, pair) in targets.enumerated() {
            try Task.checkCancellation()
            let target = pair.0
            var context = try image.cropped(target.context), label = try image.cropped(target.label)
            if target.angle != 0 { context = try context.rotatedCCW(target.angle); label = try label.rotatedCCW(target.angle) }
            let backboneContext = try model.encode(context, arm: "E"), backboneLabel = try model.encode(label, arm: "E")
            let contextFeature = adapt(backboneContext), labelFeature = adapt(backboneLabel)
            let slugs = rank(context: contextFeature, label: labelFeature).filter { cards[$0] != nil }
            // OCR runs on the source label plane and is retained as evidence. Until
            // server text/guard/layout parity is ported, it cannot promote another SKU.
            let ocrPlane = policyEvidence != nil && targets.count == 1 ? context : label
            let observations = try NativeInference.readText(ocrPlane)
            if policyEvidence != nil {
                nativeEvidence.append(["instance_id": "local-\(index)", "context_bbox": target.context,
                    "label_bbox": target.label, "physical": target.physical, "rotation_ccw": target.angle,
                    "backbone_features": [backboneContext, backboneLabel], "B0_context": pair.1,
                    "ocr_bbox": targets.count == 1 ? target.context : target.label,
                    "ocr_plane_size": [ocrPlane.width, ocrPlane.height],
                    "ocr_observations": try JSONSerialization.jsonObject(with: JSONEncoder().encode(observations))])
            }
            guard let best = slugs.first, let card = cards[best] else { continue }
            output.append(["number": index + 1, "instance_id": "local-\(index)",
                "geometry": target.physical ? target.context as Any : NSNull(), "label_bbox": target.label,
                "select_roi": target.context, "selectable": "true", "primary": targets.count == 1,
                "addressed": roi != nil, "decision": "uncertain", "best": card,
                "alternatives": slugs.dropFirst().prefix(5).compactMap { cards[$0] },
                "reasons": ["confidence_not_calibrated", "native_migration_visual_candidates"],
                "local_ocr": try JSONSerialization.jsonObject(with: JSONEncoder().encode(observations))])
        }
        if let policyEvidence {
            try Task.checkCancellation()
            let packet: [String: Any] = ["kind": "native-coreml-vision-policy-input-v1",
                "image_sha256": SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(),
                "assets_manifest_sha256": String(fingerprint.split(separator: ":").last!),
                "frame_size": [image.width, image.height], "roi": roi as Any? ?? NSNull(),
                "targets": nativeEvidence, "early_pipeline": "native-migration-v1; server early-control parity pending"]
            let bytes = try JSONSerialization.data(withJSONObject: packet, options: [.sortedKeys])
            policyEvidence(String(data: bytes, encoding: .utf8)!)
        }
        let first = output.first
        var view: [String: Any] = ["decision": output.isEmpty ? "no_target" : "uncertain",
            "mode": roi == nil ? "automatic" : "explicit_roi", "bottle_count": output.count,
            "frame_size": [image.width, image.height], "bottles": output,
            "reasons": ["confidence_not_calibrated", "ondevice_migration_candidate", "server_policy_parity_pending"],
            "profile_checksum": fingerprint, "backend_ms": Date().timeIntervalSince(started) * 1000]
        if let roi { view["roi"] = roi }
        if output.count == 1, let first { view["primary_instance_id"] = first["instance_id"]; view["best_slug"] = (first["best"] as? [String: Any])?["slug"] }
        return String(data: try JSONSerialization.data(withJSONObject: view, options: [.sortedKeys]), encoding: .utf8)!
    }
}
