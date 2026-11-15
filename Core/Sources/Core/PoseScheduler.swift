import Foundation

public struct PoseAnchors: Equatable, Sendable {
    public var wing: Double
    public var eyelid: Double
    public var tail: Double
}

/// Offset in points at stage scale.
public struct PoseOffset: Equatable, Sendable {
    public var x: Double
    public var y: Double
}

public struct Pose: Equatable, Sendable {
    public var offset: PoseOffset
    public var rotation: Double
    public var scale: Double
    public var anchors: PoseAnchors
    /// Glow level, 0...1.
    public var luminance: Double

    static let still = Pose(offset: PoseOffset(x: 0, y: 0), rotation: 0, scale: 1,
                            anchors: PoseAnchors(wing: 0, eyelid: 0, tail: 0), luminance: 0.5)
}

/// How a behaviour feeds the pose channels (weights, 0...1).
struct ChannelMix {
    var x = 0.0, y = 0.0, rotation = 0.0, scale = 0.0, wing = 0.0, eyelid = 0.0, tail = 0.0

    static func of(_ behaviour: Behaviour) -> ChannelMix {
        switch behaviour {
        case .breathe: return ChannelMix(scale: 1)
        case .blink: return ChannelMix(eyelid: 1)
        case .sway: return ChannelMix(x: 1, rotation: 1)
        case .wander: return ChannelMix(x: 1, tail: 0.5)
        case .hop: return ChannelMix(y: 1)
        case .crawl: return ChannelMix(x: 1)
        case .flutter: return ChannelMix(y: 0.5, rotation: 0.5, wing: 1)
        case .hover: return ChannelMix(y: 1, wing: 1)
        case .glide: return ChannelMix(x: 1, y: 0.5, wing: 0.5)
        case .perch: return ChannelMix(y: 0.3, tail: 1)
        case .curl: return ChannelMix(rotation: 1, scale: 1)
        case .hideInShell: return ChannelMix(scale: 1, eyelid: 0.5)
        case .glowPulse: return ChannelMix()
        case .visit: return ChannelMix(x: 1, y: 0.5)
        case .dig: return ChannelMix(x: 0.5, y: 1)
        case .peek: return ChannelMix(y: 1, eyelid: 0.5)
        case .sleep: return ChannelMix(scale: 1, eyelid: 1)
        }
    }
}

/// The inputs of one pose evaluation.
struct PoseClock {
    let resident: String
    let t: Double
    let env: Double
    let seed: UInt64

    init(resident: String, time: Double, env: Double, seed: UInt64) {
        self.resident = resident
        self.t = time
        self.env = env
        self.seed = seed
    }
}

/// Pure, closed-form pose function: no state, same inputs give the same pose.
public enum PoseScheduler {
    static let easeSeconds = 3.0
    /// Per-axis speed budget (points per second) shared by a resident's components.
    static let axisSpeedBudget = 22.0

    public static func stillPose(_ resident: String) -> Pose {
        Pose.still
    }

    public static func pose(_ resident: String, seed: UInt64, time: Double, reduceMotion: Bool) -> Pose {
        guard !reduceMotion, let entry = BehaviourTable.entry(for: resident) else { return stillPose(resident) }
        let t = max(time, 0)
        let env = envelope(resident, time: t, seed: seed)
        guard env > 0 else { return stillPose(resident) }
        var pose = Pose.still
        let moving = entry.idle.filter { $0.behaviour != .glowPulse }
        for spec in moving {
            add(spec, share: moving.count, clock: PoseClock(resident: resident, time: t, env: env, seed: seed), to: &pose)
        }
        if let glow = entry.idle.first(where: { $0.behaviour == .glowPulse }), let period = glowPeriod(for: resident, seed: seed) {
            let depth = glow.value("depth") ?? 0
            let phase = unit(seed, resident + "glow") * 2 * Double.pi
            pose.luminance = 0.5 + depth * env * sin(2 * Double.pi * t / period + phase)
        }
        return pose
    }

    public static func glowPeriod(for resident: String, seed: UInt64) -> Double? {
        guard let entry = BehaviourTable.entry(for: resident),
              let glow = (entry.idle + entry.tap).first(where: { $0.behaviour == .glowPulse }),
              let base = glow.value("period") else { return nil }
        return max(base * (1 + 0.3 * unit(seed, resident + "period")), CalmLimits.minGlowPeriod)
    }

    private static func add(_ spec: BehaviourSpec, share: Int, clock timing: PoseClock, to pose: inout Pose) {
        let key = timing.resident + spec.behaviour.rawValue
        let upper = spec.bounds("frequency")?.upperBound ?? CalmLimits.maxBodyFrequency
        let freq = min(upper, (spec.value("frequency") ?? 0.2) * (0.85 + 0.3 * unit(timing.seed, key + "f")))
        let budget = axisSpeedBudget / Double(max(share, 1)) / (2 * Double.pi * freq + 1 / easeSeconds * 1.5)
        let amp = min(spec.value("amplitude") ?? 0, budget)
        let phase = unit(timing.seed, key + "p") * 2 * Double.pi
        let wave = timing.env * sin(2 * Double.pi * freq * timing.t + phase)
        let mix = ChannelMix.of(spec.behaviour)
        pose.offset.x += amp * mix.x * wave
        pose.offset.y += amp * mix.y * wave
        pose.rotation += amp * mix.rotation * 0.01 * wave
        pose.scale += amp * mix.scale * 0.004 * wave
        pose.anchors.wing += amp * mix.wing * 0.1 * wave
        pose.anchors.eyelid += amp * mix.eyelid * 0.1 * wave
        pose.anchors.tail += amp * mix.tail * 0.1 * wave
    }

    /// 0 outside the active set, eased 0...1 at the edges of the resident's active run.
    static func envelope(_ resident: String, time: Double, seed: UInt64) -> Double {
        let interval = rotationInterval(seed: seed)
        let index = block(time, interval: interval)
        guard activeSet(block: index, seed: seed).contains(resident) else { return 0 }
        let local = time - Double(index) * interval
        var value = 1.0
        if !activeSet(block: index - 1, seed: seed).contains(resident) { value *= ease(local / easeSeconds) }
        if !activeSet(block: index + 1, seed: seed).contains(resident) { value *= ease((interval - local) / easeSeconds) }
        return value
    }

    static func ease(_ x: Double) -> Double {
        let c = min(max(x, 0), 1)
        return c * c * (3 - 2 * c)
    }

    /// Stable FNV-1a hash (Swift's own hashing is randomised per process).
    static func fnv1a(_ text: String) -> UInt64 {
        text.utf8.reduce(0xCBF2_9CE4_8422_2325) { ($0 ^ UInt64($1)) &* 0x0000_0100_0000_01B3 }
    }

    /// Deterministic value in 0..<1 from a seed and a key.
    static func unit(_ seed: UInt64, _ key: String) -> Double {
        var random = SeededRandom(seed: seed ^ fnv1a(key))
        return Double(random.next() >> 11) / Double(1 << 53)
    }
}
