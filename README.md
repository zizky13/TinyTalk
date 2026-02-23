TinyTalk — Codebase Documentation

Overview

- Purpose: TinyTalk is a SwiftUI iOS app (Swift Package/Playgrounds style) that captures a short audio snippet from the microphone, classifies it with a Core ML model, and presents a friendly summary in a bottom sheet.
- Platforms: iOS 16+ (runs from Package.swift). The project structure is Flat SwiftPM with sources at the root.

Architecture (MVVM)

- Views: SwiftUI views render UI and bind to observable state.
  - `Home`: Main screen (button, listening animation, spinner, and sheet).
  - `BottomSheetView`: Shows summary (headline + icon) and details (reason, solution).
- View Model: Orchestrates capture → inference → UI update.
  - `HomeViewModel` (MainActor): Owns published UI state, starts/stops recording, runs ML classification, and shows the sheet.
- Services: Focused, testable helpers.
  - `AudioRecorder` (MainActor): AVAudioEngine pipeline for microphone capture. Emits exactly N Float32 samples, then stops.
  - `BabyCryClassifier` (actor): Loads the Core ML model once and serializes predictions; returns a Sendable `CryPrediction`.
- Models:
  - `Result`: View-facing model (headline, icon, reason, solution).

Project Layout

- `Package.swift`: App definition, capabilities (microphone), and resource processing (assets, fonts, model package).
- `MyApp.swift`: App entry point, font registration, scene setup.
- Views
  - `Home.swift`: Main UI and button to trigger listening/processing.
  - `BottomSheetView.swift`: Modal sheet content, driven by `Result`.
  - Styles: `PrimaryButtonStyle.swift`, `FancySpinner.swift`, `AnyButtonStyle.swift`.
- ViewModels
  - `HomeViewModel.swift`: Published state (`isListening`, `isProcessing`, `result`, etc.), permission gate, and capture/ML flow.
- Services
  - `AudioRecorder.swift`: AVAudioEngine graph configuration and sample accumulation (16 kHz Float32 mono).
  - `BabyCryClassifier.swift`: Actor that returns `CryPrediction` (label + probabilities).
- CoreML interface
  - `Sources/babycryInput.swift`: Generated loader/prediction API with robust model discovery (.mlmodelc, .mlpackage, .mlmodel).
- Resources
  - `Assets.xcassets`: Colors + icons (e.g., ear, bottle, discomfort).
  - `Resources/`: Embedded fonts (OpenSans, Quicksand) and your ML model package (e.g., `babycry.mlpackage`).

Audio Pipeline

- Session: Requests/uses microphone with `.playAndRecord` and sets preferred sample rate to 16,000 Hz.
- Graph: `inputNode → mixer (Float32 mono @ 16 kHz) → mainMixer`.
- Tap: Installed on the mixer; a non-actor `TapProxy` receives buffers off the audio thread, then hops to the main actor before mutating state.
- Emission: Accumulates exactly `targetSamples` Float32 values, then emits once.

ML Pipeline

- Actor: `BabyCryClassifier` loads the model once (supports `.mlmodelc`, compiles `.mlpackage`/`.mlmodel`), serializes predictions, and returns `CryPrediction: Sendable`.
- Mapping: ViewModel converts `CryPrediction` into a `Result` with a user-friendly headline, icon, and suggestions.

UI Flow

1) Tap “Hear them”
   - ViewModel gates on microphone permission.
   - If granted: starts `AudioRecorder`.
2) Capture (~1 second by default)
   - Pulsing ring animation while listening; no UI mutation off-main.
3) Processing
   - Recording stops; spinner shows while model runs on the main actor.
4) Result
   - Bottom sheet opens with the prediction summary and details.

Concurrency and Safety

- Main-only state: `HomeViewModel` and `AudioRecorder` are MainActor-bound to ensure UI and engine/session lifecycles are mutated on the main actor only.
- Tap isolation: The audio tap closure is created in `TapProxy` (non-actor) to avoid Swift 6 executor assertions when AVAudioEngine invokes it off-main; it posts back to main before touching state.
- Sendable results: The classifier returns a Sendable struct (`CryPrediction`) instead of CoreML classes across actor boundaries.

Recording Duration (Where it’s set)

- The length of capture is controlled by these two knobs in `Services/AudioRecorder.swift`:
  - `targetSamples`: Number of Float32 samples to collect before emitting.
    - Default: `15600` (~0.975 seconds).
  - Session/sample rate: Preferred rate is set to 16,000 Hz inside `configureAndStart`.
    - Effective duration ≈ `targetSamples / sampleRate`.
- To record longer, increase `targetSamples`. For example:
  - 24,000 samples ≈ 1.5 seconds at 16 kHz.
  - 32,000 samples ≈ 2.0 seconds at 16 kHz.
- One-shot behavior: The recorder emits only once per session (first window that meets/exceeds `targetSamples`), then the ViewModel stops recording and proceeds to inference.

How to Change the Recording Length

1) Open `Services/AudioRecorder.swift` and adjust:
   - `private let targetSamples = 15600` → e.g., `24000` or `32000`.
2) (Optional) Keep preferred sample rate at 16 kHz for predictable timing:
   - `try session.setPreferredSampleRate(16_000)` (already set).
3) Re-run; the app will now capture longer before processing.

Model Packaging

- Place your model as `.mlpackage` (recommended) or `.mlmodel`/`.mlmodelc` in the app bundle.
- `Package.swift` includes `.process("Resources")` and the model package (if named explicitly) so it’s embedded.
- `Sources/babycryInput.swift` finds `.mlmodelc` first, then compiles `.mlpackage`/`.mlmodel` as needed.

Permissions

- `Package.swift` enables the microphone capability with a purpose string.
- `HomeViewModel` gates the flow if permission is not granted; it shows a friendly bottom sheet instead of attempting to record.

Troubleshooting

- TCC/permission crashes: Avoid calling `requestRecordPermission` from inside the audio graph or off-main; this code gates at the ViewModel layer and only records when already granted.
- “UI updated from background” warnings: All UI/state mutations are main-actor; the tap uses `TapProxy` to hop back to main before updating state.
- Audio quirks on Catalyst/Playgrounds: A slight delayed `engine.start()` and explicit 16 kHz conversion help stabilize startup; increase the delay (e.g., to 0.1s) if needed.

