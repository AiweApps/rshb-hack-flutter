import Foundation

public struct Detection {
    public let box: [Double]
    public let score: Float
}

extension NativeInference {
    public func bottles(_ image: PixelImage, threshold: Float = 0.4) throws -> [Detection] {
        let scaled = try image.resized(width: 640, height: 640, method: .bilinear)
        let raw = try predict(name: "WineDetectorbottle", inputName: "pixels", image: scaled, normalized: false)
        guard let logits = raw["logits"], let boxes = raw["boxes"],
              logits.shape.count == 3, boxes.count == 1200 else { throw LocalScanError.invalidModelOutput }
        let classes = logits.shape[2].intValue
        // COCO class39 is bottle in this exact frozen RT-DETR config.
        let top = (0..<logits.count).sorted {
            let a = logits[$0].floatValue, b = logits[$1].floatValue
            return a == b ? $0 < $1 : a > b
        }.prefix(300)
        var found: [Detection] = []
        for index in top where index % classes == 39 {
            let score = 1 / (1 + exp(-logits[index].floatValue))
            guard score > threshold else { continue }
            let row = index / classes
            let cx = boxes[row * 4].doubleValue * Double(image.width)
            let cy = boxes[row * 4 + 1].doubleValue * Double(image.height)
            let w = boxes[row * 4 + 2].doubleValue * Double(image.width)
            let h = boxes[row * 4 + 3].doubleValue * Double(image.height)
            let box = [max(0, cx - w / 2), max(0, cy - h / 2), min(Double(image.width), cx + w / 2), min(Double(image.height), cy + h / 2)]
            if box[2] > box[0], box[3] > box[1] { found.append(Detection(box: box, score: score)) }
        }
        return Self.nms(found, threshold: 0.6)
    }

    public func labels(_ image: PixelImage, rescue: Bool = false, fullframe: Bool = false) throws -> [Detection] {
        guard !rescue || !fullframe else { throw LocalScanError.invalidAsset("One label model role required") }
        let (padded, left, top, sx, sy) = try image.padded(side: 320, method: .bilinear, encoderCentering: false)
        let name = fullframe ? "WineDetectorlabel_fullframe" : rescue ? "WineDetectorlabel_rescue" : "WineDetectorlabel"
        let raw = try predict(name: name, inputName: "pixels", image: padded, normalized: false)
        guard let logits = raw["logits"], let boxes = raw["boxes"],
              logits.count % 2 == 0, boxes.count == logits.count * 2 else { throw LocalScanError.invalidModelOutput }
        var candidates: [Detection] = []
        for row in 0..<(logits.count / 2) {
            let score = 1 / (1 + exp(logits[row * 2].floatValue - logits[row * 2 + 1].floatValue))
            guard score >= 0.3 else { continue }
            let box = (0..<4).map { min(320, max(0, boxes[row * 4 + $0].doubleValue)) }
            if box[2] > box[0], box[3] > box[1] { candidates.append(Detection(box: box, score: score)) }
        }
        // Original torchvision: per-class top300, NMS .55, detections300.
        let kept = Self.nms(Array(candidates.sorted { $0.score > $1.score }.prefix(300)), threshold: 0.55)
        return kept.compactMap { row in
            let b = row.box
            let box = [max(0, (b[0] - Double(left)) / sx), max(0, (b[1] - Double(top)) / sy),
                       min(Double(image.width), (b[2] - Double(left)) / sx), min(Double(image.height), (b[3] - Double(top)) / sy)]
            return box[2] > box[0] && box[3] > box[1] ? Detection(box: box, score: row.score) : nil
        }
    }

    public static func overlap(_ a: [Double], _ b: [Double]) -> Double {
        let intersection = max(0, min(a[2], b[2]) - max(a[0], b[0])) * max(0, min(a[3], b[3]) - max(a[1], b[1]))
        let areaA = (a[2] - a[0]) * (a[3] - a[1]), areaB = (b[2] - b[0]) * (b[3] - b[1])
        return intersection / max(1, areaA + areaB - intersection)
    }

    private static func nms(_ input: [Detection], threshold: Double) -> [Detection] {
        let sorted = input.enumerated().sorted { $0.element.score == $1.element.score ? $0.offset < $1.offset : $0.element.score > $1.element.score }
        var kept: [Detection] = []
        for (_, detection) in sorted {
            if !kept.contains(where: { overlap(detection.box, $0.box) > threshold }) { kept.append(detection) }
        }
        return kept
    }
}
