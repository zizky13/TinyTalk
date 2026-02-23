import AVFoundation
import Foundation

@MainActor
final class AudioRecorder {
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
     var onSamples: (@MainActor ([Float]) -> Void)?
     let targetSamples = 78000
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
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
            try session.setPreferredSampleRate(16_000)
            try session.setActive(true)
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
        engine.connect(mixer, to: engine.mainMixerNode, format: desiredFormat)

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
                let slice = Array(rec.bufferStore.prefix(rec.targetSamples))
                rec.bufferStore.removeAll(keepingCapacity: false)
                rec.onSamples?(slice)
            }
        }
    }
}
