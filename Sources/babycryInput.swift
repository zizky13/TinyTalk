//
//  babycryInput.swift
//  TinyTalk
//
//  Created by Zikar Nurizky on 22/02/26.
//


//
// babycry.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
class babycryInput : MLFeatureProvider {

    /// Input audio samples to be classified as 15600 element vector of floats
    var audioSamples: MLMultiArray

    var featureNames: Set<String> { ["audioSamples"] }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "audioSamples" {
            return MLFeatureValue(multiArray: audioSamples)
        }
        return nil
    }

    init(audioSamples: MLMultiArray) {
        self.audioSamples = audioSamples
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    convenience init(audioSamples: MLShapedArray<Float>) {
        self.init(audioSamples: MLMultiArray(audioSamples))
    }

}


/// Model Prediction Output Type
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
class babycryOutput : MLFeatureProvider {

    /// Source provided by CoreML
    private let provider : MLFeatureProvider

    /// target as string value
    var target: String {
        provider.featureValue(for: "target")!.stringValue
    }

    /// targetProbability as dictionary of strings to doubles
    var targetProbability: [String : Double] {
        provider.featureValue(for: "targetProbability")!.dictionaryValue as! [String : Double]
    }

    var featureNames: Set<String> {
        provider.featureNames
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        provider.featureValue(for: featureName)
    }

    init(target: String, targetProbability: [String : Double]) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["target" : MLFeatureValue(string: target), "targetProbability" : MLFeatureValue(dictionary: targetProbability as [AnyHashable : NSNumber])])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
class babycry {
    let model: MLModel

    /// URL of model in bundle. Prefer compiled `.mlmodelc`; fallback to compile `.mlmodel`.
    class var urlOfModelInThisBundle : URL {
        #if SWIFT_PACKAGE
        let bundles: [Bundle] = [Bundle.module, Bundle.main] + Bundle.allBundles + Bundle.allFrameworks
        #else
        let bundles: [Bundle] = [Bundle.main] + Bundle.allBundles + Bundle.allFrameworks
        #endif
        for b in bundles {
            if let urls = b.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil), let u = urls.first { return u }
            if let urls = b.urls(forResourcesWithExtension: "mlpackage", subdirectory: nil) {
                for p in urls { if let c = try? MLModel.compileModel(at: p) { return c } }
            }
            if let urls = b.urls(forResourcesWithExtension: "mlmodel", subdirectory: nil) {
                for s in urls { if let c = try? MLModel.compileModel(at: s) { return c } }
            }
        }
        preconditionFailure("CoreML model not found in bundle. Place your .mlmodel in Resources/ so it’s processed and embedded.")
    }

    /**
        Construct babycry instance with an existing MLModel object.

        Usually the application does not use this initializer unless it makes a subclass of babycry.
        Such application may want to use `MLModel(contentsOfURL:configuration:)` and `babycry.urlOfModelInThisBundle` to create a MLModel object to pass-in.

        - parameters:
          - model: MLModel object
    */
    init(model: MLModel) {
        self.model = model
    }

    /**
        Construct babycry instance by automatically loading the model from the app's bundle.
    */
    @available(*, deprecated, message: "Use init(configuration:) instead and handle errors appropriately.")
    convenience init() {
        try! self.init(contentsOf: type(of:self).urlOfModelInThisBundle)
    }

    /**
        Construct a model with configuration

        - parameters:
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(configuration: MLModelConfiguration) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct babycry instance with explicit path to mlmodelc file
        - parameters:
           - modelURL: the file url of the model

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }

    /**
        Construct a model with URL of the .mlmodelc directory and configuration

        - parameters:
           - modelURL: the file url of the model
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL, configuration: MLModelConfiguration) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }

    /**
        Construct babycry instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
    class func load(configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<babycry, Error>) -> Void) {
        load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration, completionHandler: handler)
    }

    /**
        Construct babycry instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
    */
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    class func load(configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> babycry {
        try await load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct babycry instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<babycry, Error>) -> Void) {
        MLModel.load(contentsOf: modelURL, configuration: configuration) { result in
            switch result {
            case .failure(let error):
                handler(.failure(error))
            case .success(let model):
                handler(.success(babycry(model: model)))
            }
        }
    }

    /**
        Construct babycry instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
    */
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> babycry {
        let model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        return babycry(model: model)
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as babycryInput

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as babycryOutput
    */
    func prediction(input: babycryInput) throws -> babycryOutput {
        try prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as babycryInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as babycryOutput
    */
    func prediction(input: babycryInput, options: MLPredictionOptions) throws -> babycryOutput {
        let outFeatures = try model.prediction(from: input, options: options)
        return babycryOutput(features: outFeatures)
    }

    /**
        Make an asynchronous prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as babycryInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as babycryOutput
    */
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    func prediction(input: babycryInput, options: MLPredictionOptions = MLPredictionOptions()) async throws -> babycryOutput {
        let outFeatures = try await model.prediction(from: input, options: options)
        return babycryOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface

        It uses the default function if the model has multiple functions.

        - parameters:
            - audioSamples: Input audio samples to be classified as 15600 element vector of floats

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as babycryOutput
    */
    func prediction(audioSamples: MLMultiArray) throws -> babycryOutput {
        let input_ = babycryInput(audioSamples: audioSamples)
        return try prediction(input: input_)
    }

    /**
        Make a prediction using the convenience interface

        It uses the default function if the model has multiple functions.

        - parameters:
            - audioSamples: Input audio samples to be classified as 15600 element vector of floats

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as babycryOutput
    */

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    func prediction(audioSamples: MLShapedArray<Float>) throws -> babycryOutput {
        let input_ = babycryInput(audioSamples: audioSamples)
        return try prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - inputs: the inputs to the prediction as [babycryInput]
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as [babycryOutput]
    */
    func predictions(inputs: [babycryInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [babycryOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [babycryOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  babycryOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
