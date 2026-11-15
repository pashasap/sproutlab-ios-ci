import Foundation

/// The calm ceilings every animation obeys.
public enum CalmLimits {
    public static let maxSpeed = 40.0
    public static let maxBodyFrequency = 1.5
    public static let minGlowPeriod = 3.0
    public static let maxFlashRate = 3.0
    public static let maxActiveResidents = 10
    public static let maxCrossers = 3
    public static let maxPairInteractions = 1
    public static let minRotationInterval = 30.0
    public static let maxRotationInterval = 60.0
}

public struct PairInteraction: Equatable, Sendable {
    public let visitor: String
    public let host: String
}

/// Active-set rotation, crossing and pair rules (all pure, closed-form).
extension PoseScheduler {
    static let residentIds: [String] = Collectible.table.map(\.id)
    static let flowers: [String] = ["sunflower", "poppy", "dandelion"]
    static let crossingCycle = 45.0
    static let crossingWindow = 15.0

    public static func rotationInterval(seed: UInt64) -> Double {
        var random = SeededRandom(seed: seed ^ 0xA5A5_5A5A_1234_8765)
        let span = CalmLimits.maxRotationInterval - CalmLimits.minRotationInterval
        return CalmLimits.minRotationInterval + span * Double(random.below(3001)) / 3000
    }

    static func block(_ time: Double, interval: Double) -> Int {
        Int((max(time, 0) / interval + 1e-9).rounded(.down))
    }

    static func activeSet(block: Int, seed: UInt64) -> Set<String> {
        guard block >= 0 else { return [] }
        var random = SeededRandom(seed: seed ^ (UInt64(block + 1) &* 0xD1B5_4A32_D192_ED03))
        let shuffled = random.shuffled(residentIds)
        return Set(shuffled.prefix(CalmLimits.maxActiveResidents))
    }

    public static func activeSet(_ time: Double, seed: UInt64) -> Set<String> {
        activeSet(block: block(time, interval: rotationInterval(seed: seed)), seed: seed)
    }

    private static func travels(_ resident: String) -> Bool {
        let travelling: Set<Behaviour> = [.wander, .glide, .crawl]
        return BehaviourTable.entry(for: resident)?.idle.contains { travelling.contains($0.behaviour) } ?? false
    }

    /// Creatures crossing the screen now: active travellers inside their crossing window, at most 3.
    public static func crossers(_ time: Double, seed: UInt64) -> [String] {
        let t = max(time, 0)
        let active = activeSet(t, seed: seed)
        let crossing = residentIds.filter { id in
            guard active.contains(id), travels(id) else { return false }
            let offset = Double(fnv1a(id) % 1000) / 1000 * crossingCycle
            return (t + offset).truncatingRemainder(dividingBy: crossingCycle) < crossingWindow
        }
        return Array(crossing.prefix(CalmLimits.maxCrossers))
    }

    /// The bee visits one active flower during the middle of a rotation block; at most one pair.
    public static func pairInteractions(_ time: Double, seed: UInt64) -> [PairInteraction] {
        let t = max(time, 0)
        let interval = rotationInterval(seed: seed)
        let index = block(t, interval: interval)
        let active = activeSet(block: index, seed: seed)
        let fraction = (t - Double(index) * interval) / interval
        guard active.contains("honeybee"), fraction >= 0.2, fraction < 0.7 else { return [] }
        let hosts = flowers.filter { active.contains($0) }
        guard !hosts.isEmpty else { return [] }
        var random = SeededRandom(seed: seed ^ UInt64(index + 7) &* 0x9E37_79B9)
        let host = hosts[random.below(hosts.count)]
        return [PairInteraction(visitor: "honeybee", host: host)]
    }
}
