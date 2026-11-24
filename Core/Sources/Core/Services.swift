public enum SpeechOutcome: Equatable, Sendable {
    case spoken
    case voiceMissing
}

public protocol SpeechService: Sendable {
    func speak(voiceTag: String, text: String) throws -> SpeechOutcome
}

public struct AudioState: Equatable, Sendable {
    public var musicOn: Bool
    public var level: Float

    public init(musicOn: Bool, level: Float) {
        self.musicOn = musicOn
        self.level = level
    }
}

public protocol AudioService: Sendable {
    var state: AudioState { get }
    func setMusic(on: Bool)
    func setMusicLevel(_ level: Float)
    /// The single reward chime; sound on a device only.
    func playChime()
    /// Plays a rendered recipe on a bus.
    func play(_ recipe: SoundRecipe, on bus: AudioBus)
    /// The voice is about to speak; music ducks.
    func speechWillStart()
    /// The voice finished (or failed); music returns.
    func speechDidEnd()
    /// A new round opened; music is re-checked against the preference.
    func roundChanged()
    /// The visible screen changed; music is re-checked against the preference.
    func screenChanged()
}

extension AudioService {
    public func roundChanged() {}
    public func screenChanged() {}
    public func playChime() {}
    public func play(_ recipe: SoundRecipe, on bus: AudioBus) {}
    public func speechWillStart() {}
    public func speechDidEnd() {}
}

/// The default audio service: every request is ignored.
public struct SilentAudio: AudioService {
    public var state: AudioState { AudioState(musicOn: false, level: 1.0) }
    public init() {}
    public func setMusic(on: Bool) {}
    public func setMusicLevel(_ level: Float) {}
}

public protocol HapticsService: Sendable {
    func success()
    func gentle()
}

/// The platform services the view models use, plus the seed source for new rounds.
public struct Services: Sendable {
    public let speech: any SpeechService
    public let audio: any AudioService
    public let haptics: any HapticsService
    public let nextSeed: @MainActor @Sendable () -> UInt64

    public init(speech: any SpeechService, audio: any AudioService, haptics: any HapticsService,
                nextSeed: @escaping @MainActor @Sendable () -> UInt64) {
        self.speech = speech
        self.audio = audio
        self.haptics = haptics
        self.nextSeed = nextSeed
    }
}
