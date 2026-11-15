import Foundation

public enum ParticleKind: String, Sendable {
    case pollen, spore
}

/// Position in the unit square, size in points, opacity 0...1.
public struct Particle: Equatable, Sendable {
    public var kind: ParticleKind
    public var x: Double
    public var y: Double
    public var size: Double
    public var opacity: Double
}

/// Pollen by day, spores at night. Closed form from seed and time: no state.
public enum Particles {
    public static let maxCount = 120
    static let stillCount = 24

    static func kind(_ phase: DayPhase) -> ParticleKind {
        phase == .dawn || phase == .day ? .pollen : .spore
    }

    static func count(_ phase: DayPhase) -> Int {
        switch phase {
        case .dawn: return 40
        case .day: return 60
        case .dusk: return 60
        case .night: return 90
        }
    }

    public static func particles(_ t: Double, seed: UInt64, phase: DayPhase, reduceMotion: Bool) -> [Particle] {
        let time = reduceMotion ? 0 : max(t, 0)
        let total = min(reduceMotion ? stillCount : count(phase), maxCount)
        let kind = kind(phase)
        return (0..<total).map { particle($0, seed: seed, kind: kind, time: time) }
    }

    private static func fraction(_ value: Double) -> Double {
        value - value.rounded(.down)
    }

    private static func particle(_ index: Int, seed: UInt64, kind: ParticleKind, time: Double) -> Particle {
        var random = SeededRandom(seed: seed &+ UInt64(index + 1) &* 0x9E37_79B9_7F4A_7C15)
        func unit() -> Double { Double(random.next() >> 11) / Double(1 << 53) }
        let x0 = unit(), y0 = unit(), size = 1.5 + 2.5 * unit(), phase = unit() * 2 * Double.pi
        let rise = 0.004 + 0.008 * unit()
        let sway = 0.02 + 0.03 * unit()
        let direction = kind == .pollen ? 1.0 : -1.0
        let x = fraction(x0 + sway * sin(0.3 * time + phase) + 0.002 * time)
        let y = fraction(y0 + direction * rise * time)
        let twinkle = 0.5 + 0.5 * sin(0.5 * time + phase)
        let opacity = kind == .spore ? 0.3 + 0.5 * twinkle : 0.4 + 0.2 * twinkle
        return Particle(kind: kind, x: x, y: y, size: size, opacity: opacity)
    }
}
