import SwiftUI

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
        isProcessing = false
        isListening = false
    }

    // MARK: - Flow simulation (replace with real audio/inference)
    private func startFlow() {
        isListening = true
        flowTask?.cancel()
        flowTask = Task { @MainActor [weak self] in
            guard let self else { return }

            // Simulated capture phase
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if Task.isCancelled { return }

            // Processing (mocked while model is removed)
            isProcessing = true
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            let res = Result(
                headline: "Likely Hungry",
                icon: "bottle",
                reason: "Crying pattern resembles hunger cues.",
                solution: "Offer a small feed and burp midway."
            )
            self.result = res

            if Task.isCancelled { return }
            isProcessing = false
            isListening = false
            showSheet = true
        }
    }
}
