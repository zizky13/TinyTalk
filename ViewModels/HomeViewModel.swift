import SwiftUI
import AVFoundation

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published state
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var showSheet = false
    @Published var selectedDetent: PresentationDetent = .fraction(0.33)
    @Published var result: Result? = nil

    // MARK: - Private
    private var flowTask: Task<Void, Never>? = nil
    private let recorder = AudioRecorder()
    private var didTriggerInference = false

    // MARK: - Intent(s)
    func toggleListening() {
        // If already in a flow, cancel and reset
        if isListening || isProcessing {
            cancel()
            return
        }
        startFlow()
    }

    func cancel() {
        flowTask?.cancel()
        flowTask = nil
        recorder.stop()
        isProcessing = false
        isListening = false
        didTriggerInference = false
    }

//     MARK: - Flow simulation (replace with real audio/inference)
    private func startFlow() {
        isListening = true
        didTriggerInference = false
        flowTask?.cancel()
        // Permission gate (do not request here to avoid TCC callback crashes)
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            break // proceed
        case .denied, .undetermined:
            isListening = false
            result = Result(
                headline: "Microphone Access Needed",
                icon: "discomfort",
                reason: "TinyTalk needs microphone access to analyze sound.",
                solution: "Open Settings > Privacy > Microphone and allow TinyTalk, then try again."
            )
            showSheet = true
            return
        @unknown default:
            isListening = false
            return
        }
        // Begin microphone capture; run a single inference when enough samples arrive
        recorder.start { [weak self] samples in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard !self.didTriggerInference else { return }
                self.didTriggerInference = true
                self.recorder.stop()
                self.isProcessing = true
                self.isListening = false

                self.flowTask = Task { @MainActor [weak self] in
                    guard let self else { return }
                    do {
                        let output = try await BabyCryClassifier.shared.classify(samples: samples)
                        let best = output.label
                        let reason = output.probabilities
                            .sorted { $0.value > $1.value }
                            .prefix(3)
                            .map { "\($0.key): \(String(format: "%.0f%%", $0.value * 100))" }
                            .joined(separator: ", ")
                        let iconMap: [String: String] = [
                            "hungry": "bottle",
                            "burp": "burp",
                            "belly_pain": "belly-pain",
                            "discomfort": "discomfort",
                            "sleepy": "crescent"
                        ]
                        let solutionMap: [String: String] = [
                            "hungry": "Offer a feed and burp midway.",
                            "burp": "Hold upright and gently burp.",
                            "belly_pain": "Massage tummy clockwise, keep upright.",
                            "discomfort": "Check diaper, temperature, clothing.",
                            "sleepy": "Dim lights and swaddle for sleep."
                        ]
                        self.result = Result(
                            headline: best.capitalized.replacingOccurrences(of: "_", with: " "),
                            icon: iconMap[best, default: "ear"],
                            reason: reason.isEmpty ? "Top classes unavailable." : reason,
                            solution: solutionMap[best, default: "Give comfort and observe cues."]
                        )
                    } catch {
                        self.result = Result(
                            headline: "Unable to Analyze",
                            icon: "discomfort",
                            reason: "Model error: \(error.localizedDescription)",
                            solution: "Try again in a quieter environment."
                        )
                    }
                    self.isProcessing = false
                    self.showSheet = true
                }
            }
        }
    }
}
