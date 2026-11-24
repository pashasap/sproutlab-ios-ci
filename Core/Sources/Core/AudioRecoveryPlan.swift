/// Why the audio route changed; the only reasons the app reacts to.
public enum AudioRouteReason: Equatable, Sendable {
    case oldDeviceUnavailable
    case newDeviceAvailable
}

/// A system event the audio adapter reports to the recovery plan.
public enum AudioLifecycleEvent: Equatable, Sendable {
    case interruptionBegan
    case interruptionEnded(shouldResume: Bool)
    case routeChanged(reason: AudioRouteReason)
    case enteredBackground
    case becameActive
}

/// What the adapter must do in answer to an event.
public enum AudioCommand: Equatable, Sendable {
    case pauseMusic
    case resumeMusic
    case restartEngine
    case noop
}

/// The facts the recovery rules read.
public struct AudioPolicyState: Equatable, Sendable {
    public var musicOn: Bool
    public var userHasActed: Bool
    public var musicWasPlaying: Bool

    public init(musicOn: Bool, userHasActed: Bool, musicWasPlaying: Bool) {
        self.musicOn = musicOn
        self.userHasActed = userHasActed
        self.musicWasPlaying = musicWasPlaying
    }
}

/// The persisted sproutlab.music flag.
public protocol MusicPreferenceStore: AnyObject {
    var isMusicOn: Bool { get set }
}

public enum AudioRecoveryEvent: Equatable, Sendable {
    case speechEnded, roundChanged, screenChanged, sceneBecameActive, sceneBackgrounded
    case interruptionBegan
    case interruptionEnded(shouldResume: Bool)
    case toggleChanged(Bool)
}

public enum AudioRecoveryCommand: Equatable, Sendable {
    case startMusic, stopMusic, none
}

/// State machine: the music command follows the persisted preference and whether music really plays.
public struct AudioRecoveryPlan {
    private let preferences: MusicPreferenceStore
    public private(set) var isActive = true
    public private(set) var interruptionPending = false

    public init(preferences: MusicPreferenceStore) { self.preferences = preferences }

    public var musicEnabled: Bool { preferences.isMusicOn }

    public mutating func handle(_ event: AudioRecoveryEvent, isPlaying: Bool) -> AudioRecoveryCommand {
        switch event {
        case .toggleChanged(let on):
            preferences.isMusicOn = on
            return on ? .startMusic : .stopMusic
        case .interruptionBegan:
            interruptionPending = true
            return .none
        case .interruptionEnded:
            interruptionPending = false
        case .sceneBackgrounded:
            isActive = false
            return .none
        case .sceneBecameActive:
            isActive = true
        default:
            break
        }
        guard isActive, !interruptionPending else { return .none }
        if preferences.isMusicOn { return isPlaying ? .none : .startMusic }
        return isPlaying ? .stopMusic : .none
    }
}

extension AudioRecoveryPlan {
    private static let recover: [AudioCommand] = [.restartEngine, .resumeMusic]

    /// Pure rules: nothing starts before the user has acted; with music on, every
    /// interruption end, activation and route change recovers, whatever the system hint says.
    public static func next(state: AudioPolicyState, event: AudioLifecycleEvent) -> [AudioCommand] {
        guard state.userHasActed else { return [.noop] }
        switch event {
        case .interruptionBegan:
            return state.musicWasPlaying ? [.pauseMusic] : [.noop]
        case .interruptionEnded:
            return state.musicOn ? recover : [.noop]
        case .routeChanged, .becameActive:
            return state.musicOn ? recover : [.noop]
        case .enteredBackground:
            return [.noop]
        }
    }
}
