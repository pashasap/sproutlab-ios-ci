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

    /// Set only by the `-auditStop` launch argument; nil leaves the app as it always was.
    let audit: AuditLaunch?

    init(audit: AuditLaunch? = nil) {
        let music = MusicPlayer()
        let speech = SpeechAdapter()
        let base = URL.applicationSupportDirectory
        let store: any ProgressStore
        switch audit?.storeKind {
        case .inMemory: store = InMemoryProgressStore()
        case .file, nil: store = FileProgressStore(url: base.appendingPathComponent("progress.json"))
        }
        let fixedSeed = audit?.seed
        let services = Services(speech: speech, audio: music, haptics: HapticsAdapter(),
                                nextSeed: { fixedSeed ?? UInt64.random(in: 0...UInt64.max) })
        self.audit = audit
        self.music = music
        self.speech = speech
        self.store = store
        app = AppViewModel(store: store, services: services)
    }

    func didLaunch() {
        app.launch()
        if let audit { openAuditStop(audit) }
        frames.start()
        launchSeconds = ProcessInfo.processInfo.systemUptime - started
    }

    /// Opens the screen the audit state names; music stays off and nothing touches the network.
    private func openAuditStop(_ audit: AuditLaunch) {
        app.setMusic(audit.musicOn)
        switch audit.state.screen {
        case .welcome: break
        case .trail: app.play()
        case .round, .summary:
            app.play()
            if !audit.state.levelId.isEmpty { app.startLevel(audit.state.levelId) }
        case .terrarium: app.openTerrarium()
        case .diagnostics: app.setDiagnosticsVisible(true)
        case .gallery, .journal: app.play()
        }
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
