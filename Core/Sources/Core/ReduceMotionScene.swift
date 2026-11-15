import Foundation

public enum TapStep: String, Equatable, Sendable {
    case highlightRing, call, nameBubble
}

/// What a tap does; `motion` is the distance travelled (0 under Reduce Motion).
public struct TapResponse: Equatable, Sendable {
    public var steps: [TapStep]
    public var motion: Double
}

/// A still composition per phase when Reduce Motion is on; the tap shows ring, call and name bubble in place.
public enum ReduceMotionScene {
    static let seed: UInt64 = 1

    public static func composition(
        _ phase: DayPhase, _ scheme: ColourScheme, time: Double, reduceMotion: Bool
    ) -> SceneComposition {
        var scene = SkyPalette.stillComposition(phase, scheme)
        guard !reduceMotion else { return scene }
        scene.particles = Particles.particles(time, seed: seed, phase: phase, reduceMotion: false)
        scene.isStill = false
        return scene
    }

    public static func tap(_ phase: DayPhase, reduceMotion: Bool) -> TapResponse {
        TapResponse(steps: [.highlightRing, .call, .nameBubble], motion: 0)
    }
}
