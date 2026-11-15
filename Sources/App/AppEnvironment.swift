import Foundation
import Core

/// Wires the Core view model to the real platform adapters.
@MainActor
final class AppEnvironment {
    let app: AppViewModel
    let frames = FrameMonitor()
    let music: MusicPlayer
    let speech: SpeechAdapter
    private let store: any ProgressStore
    var launchSeconds: Double = 0
    private let started = ProcessInfo.processInfo.systemUptime

    init() {
        let music = MusicPlayer()
        let speech = SpeechAdapter()
        let base = URL.applicationSupportDirectory
        let store = FileProgressStore(url: base.appendingPathComponent("progress.json"))
        let services = Services(speech: speech, audio: music, haptics: HapticsAdapter(),
                                nextSeed: { UInt64.random(in: 0...UInt64.max) })
        self.music = music
        self.speech = speech
        self.store = store
        app = AppViewModel(store: store, services: services)
    }

    func didLaunch() {
        app.launch()
        frames.start()
        launchSeconds = ProcessInfo.processInfo.systemUptime - started
    }

    /// The terrarium sheet content for the current save, wired to the real audio.
    func terrariumContent() -> TerrariumSheetContent {
        let content = ChromePresentation.terrariumSheetContent(store: store, clock: SystemClock(),
                                                               speech: speech, language: app.language)
        if case let .terrarium(model) = content { model.audio = music }
        return content
    }

    var diagnostics: DiagnosticsModel {
        DiagnosticsModel(source: AppDiagnostics(environment: self))
    }
}

/// Reads live measurements from the adapters; only ever read on the main thread.
struct AppDiagnostics: DiagnosticsSource, @unchecked Sendable {
    let environment: AppEnvironment

    var version: String { Self.bundleValue("CFBundleShortVersionString") }
    var build: String { Self.bundleValue("CFBundleVersion") }
    var launchSeconds: Double { MainActor.assumeIsolated { environment.launchSeconds } }
    var droppedFrames: Int { MainActor.assumeIsolated { environment.frames.droppedFrames } }
    var lastSave: SaveReport? { MainActor.assumeIsolated { environment.app.lastSave } }
    var audioEngine: AudioEngineState { environment.music.engineState }
    var frenchVoiceName: String? { environment.speech.voiceName(tag: "fr-FR") }
    var englishVoiceName: String? { environment.speech.voiceName(tag: "en-US") }

    private static func bundleValue(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "-"
    }
}
