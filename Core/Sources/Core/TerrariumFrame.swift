import Foundation

/// The two switches that change how a frame is built.
public struct FrameFlags: Equatable, Sendable {
    public var reduceMotion: Bool
    public var lowPower: Bool

    public init(reduceMotion: Bool, lowPower: Bool) {
        self.reduceMotion = reduceMotion
        self.lowPower = lowPower
    }
}

/// The sun and moon dial as drawn: the current phase and its hit area.
public struct DialState: Equatable, Sendable {
    public let phase: DayPhase
    public let hitSize: CGSize

    public static func == (lhs: DialState, rhs: DialState) -> Bool {
        lhs.phase == rhs.phase && lhs.hitSize.width == rhs.hitSize.width && lhs.hitSize.height == rhs.hitSize.height
    }
}

extension SunMoonDial {
    /// The phase after this one: dawn, day, dusk, night, dawn.
    public static func next(_ phase: DayPhase) -> DayPhase {
        let all = DayPhase.allCases
        let index = all.firstIndex(of: phase) ?? 0
        return all[(index + 1) % all.count]
    }

    /// Start angle in degrees of a phase's quarter of the dial.
    public static func angle(_ phase: DayPhase) -> Double {
        Double(DayPhase.allCases.firstIndex(of: phase) ?? 0) * 90
    }
}

/// Everything the terrarium view draws for one instant, composed from the Core rules. Pure and Equatable.
public struct TerrariumFrame: Equatable, Sendable {
    static let bodyTokenPrefix = "colour.body."

    public let seed: UInt64
    public let phase: DayPhase
    /// One pose per animated (arrived and active) resident.
    public let poses: [String: Pose]
    /// The light-scheme composition of the phase (still under Reduce Motion).
    public let composition: SceneComposition
    public let particles: [Particle]
    public let dial: DialState
    public let interval: TimeInterval

    public var sky: SkyGradient { composition.sky }
    public var tint: RGBColour { composition.tint }

    public func sky(_ scheme: ColourScheme) -> SkyGradient {
        SkyPalette.sky(phase, scheme)
    }

    public func tint(_ scheme: ColourScheme) -> RGBColour {
        SkyPalette.tint(phase, scheme)
    }

    /// The creature body colours; identical in every scheme.
    public func creatureTokens(_ scheme: ColourScheme) -> [String: RGBColour] {
        var result: [String: RGBColour] = [:]
        // Only the base body tokens: derived ".back" shades belong to the dark-adapted chrome.
        for token in ColourTokens.allTokens
        where token.hasPrefix(Self.bodyTokenPrefix) && !token.dropFirst(Self.bodyTokenPrefix.count).contains(".") {
            if let value = ColourTokens.value(token, scheme) { result[token] = value }
        }
        return result
    }

    public func isPaused(visible: Bool) -> Bool {
        FramePolicy.timelinePaused(visible: visible)
    }

    @MainActor
    public static func make(_ model: TerrariumViewModel, phase: DayPhase, time: TimeInterval,
                            flags: FrameFlags) -> TerrariumFrame {
        let seed = ReduceMotionScene.seed
        let still = flags.reduceMotion
        let at = still ? 0 : max(time, 0)
        let composition = ReduceMotionScene.composition(phase, .light, time: at, reduceMotion: still)
        let arrived = Set(model.residents.filter { $0.state != .notArrived }.map(\.id))
        var poses: [String: Pose] = [:]
        for id in PoseScheduler.activeSet(at, seed: seed).intersection(arrived) {
            poses[id] = still ? PoseScheduler.stillPose(id)
                : SkyPalette.pose(id, phase, seed: seed, time: at)
        }
        let particles = still ? composition.particles
            : Particles.particles(at, seed: seed, phase: phase, reduceMotion: false)
        return TerrariumFrame(
            seed: seed, phase: phase, poses: poses, composition: composition, particles: particles,
            dial: DialState(phase: phase, hitSize: CGSize(width: SunMoonDial.size, height: SunMoonDial.size)),
            interval: FramePolicy.frameInterval(lowPower: flags.lowPower))
    }
}
