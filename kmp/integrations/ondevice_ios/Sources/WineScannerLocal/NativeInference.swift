import Foundation
import CoreML
import Vision
import Accelerate

public struct TextObservation: Codable {
    public let text: String
    public let score: Float
    public let bbox: [Double]
    public let polygon: [[Double]]
}

/// Only real Core ML/Vision execution. Caller owns operation lifetime and serial scheduling.
public final class NativeInference {
    private var models: [String: MLModel]
    private let ownedCompiledModels: [URL]
    private var deadline = Double.infinity
    private var remainingForwards = 256

    public func beginRequest() {
        deadline = ProcessInfo.processInfo.systemUptime + 180
        remainingForwards = 256
    }

    public init(modelDirectory: URL, names: [String]) throws {
        let configuration = MLModelConfiguration()
        // FP32 migration control. Device acceleration is a separate measured stage.
        configuration.computeUnits = .cpuOnly
        var loaded: [String: MLModel] = [:]
        var created: [URL] = []
        do { for name in names {
            try Task.checkCancellation()
            let compiled = modelDirectory.appendingPathComponent(name + ".mlmodelc")
            let package = modelDirectory.appendingPathComponent(name + ".mlpackage")
            let location: URL
            if FileManager.default.fileExists(atPath: compiled.path) { location = compiled }
            else if FileManager.default.fileExists(atPath: package.path) {
                location = try MLModel.compileModel(at: package)
                created.append(location)
            }
            else { throw LocalScanError.missingAsset(name) }
            loaded[name] = try MLModel(contentsOf: location, configuration: configuration)
        }} catch {
            loaded.removeAll()
            for url in created { try? FileManager.default.removeItem(at: url) }
            throw error
        }
        models = loaded
        ownedCompiledModels = created
    }

    deinit {
        // Drop the models before removing exactly the compiler outputs we own.
        models.removeAll()
        for url in ownedCompiledModels { try? FileManager.default.removeItem(at: url) }
    }

    public func predict(name: String, inputName: String, image: PixelImage, normalized: Bool) throws -> [String: MLMultiArray] {
        let count = image.width * image.height
        let input = try MLMultiArray(shape: [1, 3, NSNumber(value: image.height), NSNumber(value: image.width)], dataType: .float32)
        let values = input.dataPointer.bindMemory(to: Float.self, capacity: count * 3)
        for pixel in 0..<count { for channel in 0..<3 {
            let rescaled = Float(image.rgb[pixel * 3 + channel]) / 255
            values[channel * count + pixel] = normalized ? (rescaled - 0.5) / 0.5 : rescaled
        }}
        return try predict(name: name, inputName: inputName, input: input)
    }

    public func predict(name: String, inputName: String, input: MLMultiArray) throws -> [String: MLMultiArray] {
        try Task.checkCancellation()
        guard ProcessInfo.processInfo.systemUptime < deadline, remainingForwards > 0 else { throw LocalScanError.requestBudgetExceeded }
        remainingForwards -= 1
        guard let model = models[name] else { throw LocalScanError.missingAsset(name) }
        let features = try MLDictionaryFeatureProvider(dictionary: [inputName: input])
        let output = try model.prediction(from: features)
        var result: [String: MLMultiArray] = [:]
        for key in output.featureNames { result[key] = output.featureValue(for: key)?.multiArrayValue }
        return result
    }

    public func encode(_ image: PixelImage, arm: String) throws -> [Float] {
        let (padded, _, _, _, _) = try image.padded(side: 384, method: .bicubic, encoderCentering: true)
        guard let output = try predict(name: "WineEncoder" + arm, inputName: "pixel_values", image: padded, normalized: true)["features"],
              output.count == 768 else { throw LocalScanError.invalidModelOutput }
        return (0..<768).map { output[$0].floatValue }
    }

    public static func readText(_ image: PixelImage) throws -> [TextObservation] {
        let request = VNRecognizeTextRequest()
        request.revision = VNRecognizeTextRequestRevision3
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ru-RU", "en-US"]
        request.usesLanguageCorrection = false
        request.automaticallyDetectsLanguage = false
        try VNImageRequestHandler(cgImage: image.cgImage(), options: [:]).perform([request])
        return (request.results ?? []).compactMap { observation in
            guard let best = observation.topCandidates(1).first else { return nil }
            let rect = observation.boundingBox
            return TextObservation(text: best.string, score: best.confidence,
                bbox: [rect.minX * Double(image.width), (1 - rect.maxY) * Double(image.height),
                       rect.maxX * Double(image.width), (1 - rect.minY) * Double(image.height)],
                polygon: [observation.topLeft, observation.topRight, observation.bottomRight, observation.bottomLeft].map {
                    [$0.x * Double(image.width), (1 - $0.y) * Double(image.height)]
                })
        }
    }
}
