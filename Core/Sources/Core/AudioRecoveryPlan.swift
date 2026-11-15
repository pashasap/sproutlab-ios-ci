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

public enum AudioRecoveryPlan {
    private static let recover: [AudioCommand] = [.restartEngine, .resumeMusic]

    /// Pure rules: nothing starts before the user has acted; a resume needs music on
    /// (and, after an interruption, music that was playing).
    public static func next(state: AudioPolicyState, event: AudioLifecycleEvent) -> [AudioCommand] {
        guard state.userHasActed else { return [.noop] }
        switch event {
        case .interruptionBegan:
            return state.musicWasPlaying ? [.pauseMusic] : [.noop]
        case .interruptionEnded(let shouldResume):
            return shouldResume && state.musicOn && state.musicWasPlaying ? recover : [.noop]
        case .routeChanged, .becameActive:
            return state.musicOn ? recover : [.noop]
        case .enteredBackground:
            return [.noop]
        }
    }
}
