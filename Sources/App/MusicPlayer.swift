import AVFoundation
import Core

/// The music preference as the plan reads it; AppViewModel persists it in the progress record.
private final class MusicFlag: MusicPreferenceStore {
    var isMusicOn = false
}

/// The audio adapter: an ambient session, one mixer per bus, and the lifecycle feed into AudioRecoveryPlan.
/// Used only from the main thread.
final class MusicPlayer: AudioService, @unchecked Sendable {
    private static let sampleRate = 22_050

    private let engine = AVAudioEngine()
    private let musicNode = AVAudioPlayerNode()
    private let effectNode = AVAudioPlayerNode()
    private let voiceNode = AVAudioPlayerNode()
    private var busMixers: [AudioBus: AVAudioMixerNode] = [:]
    private var effectNodes: [AudioBus: AVAudioPlayerNode] = [:]
    private var prepared = false
    private var failed = false
    private var musicOn: Bool {
        get { flag.isMusicOn }
        set { flag.isMusicOn = newValue }
    }
    private let flag = MusicFlag()
    private lazy var plan = AudioRecoveryPlan(preferences: flag)
    private var userHasActed = false
    private var musicWasPlaying = false
    private var level: Float = 1.0
    private var mixer = BusMixer()
    private var observers: [NSObjectProtocol] = []

    init() { observeSession() }

    deinit { observers.forEach { NotificationCenter.default.removeObserver($0) } }

    var state: AudioState { AudioState(musicOn: musicOn, level: level) }

    var engineState: AudioEngineState {
        if failed { return .error }
        return engine.isRunning ? .running : .stopped
    }

    func setMusic(on: Bool) {
        musicOn = on
        if on { userHasActed = true }
        handle(.toggleChanged(on))
    }

    func setMusicLevel(_ newLevel: Float) {
        level = newLevel
        applyMusicGain()
    }

    func speechWillStart() {
        mixer.speechWillStart()
        applyMusicGain()
    }

    func speechDidEnd() {
        mixer.speechDidEnd()
        applyMusicGain()
        handle(.speechEnded)
    }

    func playChime() { play(MotifTable.celebration, on: .effects) }

    /// A short rendered recipe on its bus; failures never propagate.
    func play(_ recipe: SoundRecipe, on bus: AudioBus) {
        userHasActed = true
        guard let buffer = Self.buffer(from: SoundRenderer.render(recipe, sampleRate: Self.sampleRate)) else { return }
        guard bus != .music, ensureRunning(), let node = effectNodes[bus] else { return }
        node.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !node.isPlaying { node.play() }
    }

    /// Feeds a scene-phase change into the recovery rules.
    func scenePhaseChanged(background: Bool) {
        handle(background ? .sceneBackgrounded : .sceneBecameActive)
    }

    // MARK: lifecycle

    private func observeSession() {
        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: session,
                                            queue: .main) { [weak self] note in
            self?.interruption(note)
        })
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: session,
                                            queue: .main) { [weak self] note in
            self?.routeChange(note)
        })
    }

    private func interruption(_ note: Notification) {
        let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
        switch raw.flatMap(AVAudioSession.InterruptionType.init(rawValue:)) {
        case .began:
            handle(.interruptionBegan)
        case .ended:
            let flags = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let resume = AVAudioSession.InterruptionOptions(rawValue: flags).contains(.shouldResume)
            handle(.interruptionEnded(shouldResume: resume))
        default:
            break
        }
    }

    private func routeChange(_ note: Notification) {
        let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
        switch raw.flatMap(AVAudioSession.RouteChangeReason.init(rawValue:)) {
        case .oldDeviceUnavailable, .newDeviceAvailable: handle(.screenChanged)
        default: break
        }
    }

    /// Feeds one event to the recovery plan and executes the command it returns.
    /// The plan reads the persisted flag and the true playing state; this only executes.
    private func handle(_ event: AudioRecoveryEvent) {
        let playing = engine.isRunning && musicNode.isPlaying
        let command = plan.handle(event, isPlaying: playing)
        guard userHasActed || event == .toggleChanged(true) else { return }
        switch command {
        case .startMusic:
            if !playing { engine.stop() }
            startMusic()
        case .stopMusic:
            pauseMusic()
        case .none:
            break
        }
        musicWasPlaying = engine.isRunning && musicNode.isPlaying
    }

    /// App-level triggers the plan also reacts to.
    func roundChanged() { handle(.roundChanged) }
    func screenChanged() { handle(.screenChanged) }

    // MARK: engine

    private func startMusic() {
        guard ensureRunning() else { return }
        applyMusicGain()
        if !musicNode.isPlaying { musicNode.play() }
        musicWasPlaying = true
    }

    private func pauseMusic() {
        if musicNode.isPlaying { musicNode.pause() }
        musicWasPlaying = false
    }

    private func applyMusicGain() {
        busMixers[.music]?.outputVolume = mixer.gain(for: .music) * level
    }

    /// Ambient session (mixes with other audio, silenced by the ring switch).
    private func activateAmbientSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.ambient, mode: .default, options: [])
        try session.setActive(true, options: [])
    }

    private func ensureRunning() -> Bool {
        guard prepare() else { return false }
        do {
            try activateAmbientSession()
            if !engine.isRunning { try engine.start() }
            failed = false
            return true
        } catch {
            failed = true
            return false
        }
    }

    private func prepare() -> Bool {
        if prepared { return true }
        guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(Self.sampleRate), channels: 1),
              let music = Self.buffer(from: MusicRenderer.render(sampleRate: Self.sampleRate)) else {
            failed = true
            return false
        }
        let nodes: [AudioBus: AVAudioPlayerNode] = [.music: musicNode, .effects: effectNode, .voice: voiceNode]
        for (bus, node) in nodes {
            let busMixer = AVAudioMixerNode()
            engine.attach(node)
            engine.attach(busMixer)
            engine.connect(node, to: busMixer, format: format)
            engine.connect(busMixer, to: engine.mainMixerNode, format: format)
            busMixers[bus] = busMixer
            if bus != .music { effectNodes[bus] = node }
        }
        musicNode.scheduleBuffer(music, at: nil, options: .loops)
        prepared = true
        return true
    }

    private static func buffer(from samples: [Float]) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0] else { return nil }
        for (index, value) in samples.enumerated() { channel[index] = value }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        return buffer
    }
}
