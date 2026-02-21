import CoreML
import Foundation

actor BabyCryClassifier {
    static let shared = BabyCryClassifier()

    private var model: babycry?

    private init() {}

    func ensureLoaded() throws {
        if model == nil {
            let config = MLModelConfiguration()
            model = try babycry(configuration: config)
        }
    }

    func classify(samples: [Float]) throws -> babycryOutput {
        try ensureLoaded()
        guard let model else { throw NSError(domain: "BabyCryClassifier", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"]) }

        // Ensure correct input length. Model expects 15600 elements.
        let expected = 15600
        guard samples.count >= expected else {
            // Pad with zeros if too short
            let padded = samples + Array(repeating: 0.0, count: expected - samples.count)
            let array = try MLMultiArray(shape: [NSNumber(value: expected)], dataType: .float32)
            for (i, v) in padded.prefix(expected).enumerated() { array[i] = NSNumber(value: v) }
            return try model.prediction(audioSamples: array)
        }

        let array = try MLMultiArray(shape: [NSNumber(value: expected)], dataType: .float32)
        for i in 0..<expected { array[i] = NSNumber(value: samples[i]) }
        return try model.prediction(audioSamples: array)
    }
}

