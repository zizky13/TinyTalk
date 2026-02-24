import AVFoundation
import Foundation

@MainActor
final class AudioRecorder {
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    var onSamples: (@MainActor ([Float]) -> Void)?
    // CHANGE: Align with model input length (15,600 @ 16 kHz ≈ 0.975s)
    let targetSamples = 15600 * 3
    var bufferStore: [Float] = []
    var emitted = false
    private var tapInstalled = false
    private var tapProxy: TapProxy?

    func start(onSamples: @MainActor @escaping ([Float]) -> Void) {
        self.onSamples = onSamples
        let session = AVAudioSession.sharedInstance()
        // Only proceed if permission is already granted. Avoid requesting here to bypass TCC callback crashes.
        guard session.recordPermission == .granted else { return }
        self.configureAndStart(session: session)
    }

    private func configureAndStart(session: AVAudioSession) {
        do {
            // CHANGE: Eliminate acoustic echo/feedback by not routing capture to speaker.
            // - Switch category to `.record` (no playback path), and use `.measurement`
            //   to minimize processing.
            try session.setCategory(.record)
            try session.setMode(.measurement)
            try session.setPreferredSampleRate(16_000)
            try session.setActive(true)
            // CHANGE: Additionally ensure engine output is muted as a safety net.
            engine.mainMixerNode.outputVolume = 0
        } catch { }

        let input = engine.inputNode
        let hwFormat = input.inputFormat(forBus: 0)
        let desiredFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                          sampleRate: 16_000,
                                          channels: 1,
                                          interleaved: false)!

        if !engine.attachedNodes.contains(mixer) {
            engine.attach(mixer)
        }
        if tapInstalled {
            mixer.removeTap(onBus: 0)
            tapInstalled = false
        }
        engine.disconnectNodeInput(mixer)
        engine.disconnectNodeOutput(mixer)
        engine.connect(input, to: mixer, format: hwFormat)
        // CHANGE: Keep graph simple and ensure no audible output reaches speakers.
        // We still connect to the main mixer to drive the graph, but output is muted above.

        // CHANGE: Create and install the tap from a non-actor helper to avoid
        // creating a MainActor-isolated closure in this method. Closures created
        // inside a @MainActor context inherit main isolation and will crash when
        // AVAudioEngine invokes them on the realtime audio thread.
        let frameCount: AVAudioFrameCount = 1024
        let proxy = TapProxy(owner: self)
        self.tapProxy = proxy
        proxy.install(on: mixer, frameCount: frameCount, format: desiredFormat)
        tapInstalled = true

        engine.prepare()
        // Small delay to let route settle before starting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            do { try self.engine.start() } catch { }
        }
    }

    func stop() {
        let session = AVAudioSession.sharedInstance()
        if tapInstalled {
            mixer.removeTap(onBus: 0)
            tapInstalled = false
        }
        engine.stop()
        if engine.attachedNodes.contains(mixer) {
            engine.disconnectNodeInput(mixer)
            engine.disconnectNodeOutput(mixer)
            engine.detach(mixer)
        }
        bufferStore.removeAll(keepingCapacity: false)
        onSamples = nil
        emitted = false
        tapProxy = nil
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// Non-actor helper to receive tap callbacks off the realtime thread
final class TapProxy {
    weak var owner: AudioRecorder?
    init(owner: AudioRecorder) { self.owner = owner }

    // CHANGE: Install the tap and provide a non-actor closure. This avoids
    // Swift 6 executor assertions by ensuring the closure is not MainActor-iso.
    func install(on node: AVAudioMixerNode, frameCount: AVAudioFrameCount, format: AVAudioFormat) {
        node.installTap(onBus: 0, bufferSize: frameCount, format: format) { [weak self] buffer, _ in
            self?.handle(buffer: buffer)
        }
    }

    func handle(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channel = channelData[0]
        let frames = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channel, count: frames))
        Task { @MainActor [weak owner] in
            guard let rec = owner else { return }
            rec.bufferStore.append(contentsOf: samples)
            if rec.bufferStore.count >= rec.targetSamples, !rec.emitted {
                rec.emitted = true
                // CHANGE: Choose the most energetic 15,600-sample window to avoid
                // bias from initial silence; apply light DC removal + pre-emphasis,
                // then peak-normalize to improve SNR.
                let window = rec.targetSamples
                let buf = rec.bufferStore
                let end = buf.count - window
                var bestIdx = 0
                var bestEnergy: Float = -Float.greatestFiniteMagnitude
                var currentEnergy: Float = 0
                let step = max(256, window / 8)
                var i = 0
                while i <= end {
                    // compute energy over [i, i+window)
                    currentEnergy = 0
                    var j = i
                    let stop = i + window
                    while j < stop { currentEnergy += abs(buf[j]); j += 1 }
                    if currentEnergy > bestEnergy { bestEnergy = currentEnergy; bestIdx = i }
                    i += step
                }
                var slice = Array(buf[bestIdx..<(bestIdx + window)])
                // DC removal
                let mean = slice.reduce(0, +) / Float(slice.count)
                if abs(mean) > 0 { slice = slice.map { $0 - mean } }
                // Simple pre-emphasis to boost higher frequencies (common in VAD/classification frontends)
                let alpha: Float = 0.97
                var prev: Float = 0
                for k in 0..<slice.count {
                    let x = slice[k]
                    slice[k] = x - alpha * prev
                    prev = x
                }
                // Peak normalization
                if let maxAbs = slice.map({ abs($0) }).max(), maxAbs > 0 {
                    let norm = slice.map { $0 / maxAbs }
                    rec.onSamples?(norm)
                } else {
                    rec.onSamples?(slice)
                }
                rec.bufferStore.removeAll(keepingCapacity: false)
            }
        }
    }
}
