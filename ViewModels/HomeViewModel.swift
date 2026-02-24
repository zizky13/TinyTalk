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
                verdict: "Cannot detect",
                icon: "discomfort",
                reason: "TinyTalk needs microphone access to analyze sound.",
                solution: ["Open Settings > Privacy > Microphone and allow TinyTalk, then try again."]
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
                        let headlineMap: [String: String] = [
                            "hungry": "Someone’s Hungry!",
                            "tired": "Time for a nap",
                            "cool_hot": "Let’s get cozy.",
                            "burping": "Need to let a bubble out?",
                            "discomfort" : "Something isn’t quite right",
                            "belly pain": "A little tummy trouble."
                        ]
                        let iconMap: [String: String] = [
                            "hungry": "bottle",
                            "tired": "crescent",
                            "cool_hot": "temperature",
                            "burping": "burping",
                            "discomfort": "discomfort",
                            "belly pain": "belly-pain"
                        ]
                        let solutionMap: [String: [String]] = [
                            "hungry": ["Offer a breast or bottle immediately.", "Check if the milk flow is comfortable for them.", "Look for 'early cues' like lip-smacking next time."],
                            "burp": ["Sit them upright and support their chin.", "Give firm but gentle pats on the back.", "Wait a few minutes; sometimes the bubble needs time to move."],
                            "cool_hot": ["Feel their chest or back (hands and feet are usually colder).", "Add or remove one layer of clothing.", "Ensure the room temperature is between 20-22°C."],
                            "belly pain": ["Try the 'bicycle legs' motion to help move gas.", "Gently massage the tummy in a clockwise direction.", "Hold them in the 'football hold' across your forearm."],
                            "discomfort": ["Check for a wet or soiled diaper.", "Ensure clothing isn't too tight or itchy.", "Check for a 'hair tourniquet' around fingers or toes."],
                            "tired": ["Move to a dim, quiet room.", "Try a gentle swaddle to prevent the startle reflex.", "Rock or sway with a steady, rhythmic motion."]
                        ]
                        let reasonMap: [String: String] = [
                            "hungry": "Your baby is making a 'Neh' sound, which is a reflex triggered when the tongue touches the roof of the mouth",
                            "burp": "This sound is often a short, abrupt 'Eh' produced when air is trapped in the chest or esophagus.",
                            "tired": "This cry often sounds like a breathy yawn or a long, drawn-out 'owh' sound as the baby's mouth stays open.",
                            "cool_hot" : "This sound is often a short, abrupt 'Eh' produced when air is trapped in the chest or esophagus.",
                            "discomfort": "This is usually a whiny, grumbly cry that isn't as intense as hunger. It’s their way of saying 'I'm annoyed.'",
                            "belly pain": "This is usually a sharp, intense cry. You might notice your baby pulling their knees up to their chest or having a stiff tummy."
                        ]
                        self.result = Result(
                            headline: headlineMap[best, default: "Something isn't quite right"],
                            verdict: best,
                            icon: iconMap[best, default: "ear"],
                            reason: reasonMap[best, default: "out of context"],
                            solution: solutionMap[best, default: ["Give comfort and observe cues."]]
                        )
                    } catch {
                        self.result = Result(
                            headline: "Unable to Analyze",
                            verdict: "There is some issue",
                            icon: "discomfort",
                            reason: "Model error: \(error.localizedDescription)",
                            solution: ["Try again in a quieter environment."]
                        )
                    }
                    self.isProcessing = false
                    self.showSheet = true
                }
            }
        }
    }
}
