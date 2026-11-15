import Foundation

public struct SkyGradient: Equatable, Sendable {
    public var top: RGBColour
    public var bottom: RGBColour
}

/// Unit-length direction of highlights and contact shadows.
public struct LightDirection: Equatable, Sendable {
    public var x: Double
    public var y: Double
}

public struct GlowSpec: Equatable, Sendable {
    public var isOn: Bool
    public var gradient: [RGBColour]
    public var intensity: Double
}

public struct SceneComposition: Equatable, Sendable {
    public var phase: DayPhase
    public var sky: SkyGradient
    public var tint: RGBColour
    public var light: LightDirection
    public var ground: RGBColour
    public var chrome: RGBColour
    public var glow: GlowSpec
    public var particles: [Particle]
    public var isStill: Bool
}

/// Per phase and per appearance: sky, tint, light, ground, chrome, who is awake and who glows.
/// Dark lowers sky, ground and chrome only; creature colours never change.
public enum SkyPalette {
    public static let closedEyelid: Double = 1
    static let mushroom = "glowing-mushroom"
    static let diurnal: Set<String> = ["honeybee", "butterfly", "ladybug", "robin"]
    static let nocturnal: Set<String> = ["cricket", mushroom]
    static let darkSkyFactor = 0.3
    static let darkTintFactor = 0.75

    private static func rgb(_ r: Double, _ g: Double, _ b: Double) -> RGBColour {
        RGBColour(r: r, g: g, b: b)
    }

    private static func dimmed(_ c: RGBColour, _ factor: Double) -> RGBColour {
        rgb(c.r * factor, c.g * factor, c.b * factor)
    }

    public static func sky(_ phase: DayPhase, _ scheme: ColourScheme) -> SkyGradient {
        let light: SkyGradient
        switch phase {
        case .dawn: light = SkyGradient(top: rgb(0.99, 0.80, 0.70), bottom: rgb(0.99, 0.92, 0.80))
        case .day: light = SkyGradient(top: rgb(0.55, 0.80, 0.98), bottom: rgb(0.85, 0.94, 1.00))
        case .dusk: light = SkyGradient(top: rgb(0.60, 0.50, 0.75), bottom: rgb(0.98, 0.70, 0.50))
        case .night: light = SkyGradient(top: rgb(0.35, 0.40, 0.65), bottom: rgb(0.60, 0.65, 0.85))
        }
        guard scheme == .dark else { return light }
        return SkyGradient(top: dimmed(light.top, darkSkyFactor), bottom: dimmed(light.bottom, darkSkyFactor))
    }

    public static func tint(_ phase: DayPhase, _ scheme: ColourScheme) -> RGBColour {
        let light: RGBColour
        switch phase {
        case .dawn: light = rgb(1.00, 0.90, 0.85)
        case .day: light = rgb(1.00, 1.00, 0.97)
        case .dusk: light = rgb(1.00, 0.82, 0.70)
        case .night: light = rgb(0.70, 0.75, 0.95)
        }
        return scheme == .dark ? dimmed(light, darkTintFactor) : light
    }

    public static func lightDirection(_ phase: DayPhase, _ scheme: ColourScheme) -> LightDirection {
        switch phase {
        case .dawn: return LightDirection(x: -0.8, y: -0.6)
        case .day: return LightDirection(x: 0, y: -1)
        case .dusk: return LightDirection(x: 0.8, y: -0.6)
        case .night: return LightDirection(x: 0.6, y: -0.8)
        }
    }

    public static func ground(_ phase: DayPhase, _ scheme: ColourScheme) -> RGBColour {
        switch (phase, scheme) {
        case (.dawn, .light): return rgb(0.97, 0.90, 0.85)
        case (.day, .light): return rgb(0.95, 0.93, 0.84)
        case (.dusk, .light): return rgb(0.95, 0.86, 0.80)
        case (.night, .light): return rgb(0.86, 0.90, 0.96)
        case (.dawn, .dark): return rgb(0.09, 0.09, 0.10)
        case (.day, .dark): return rgb(0.07, 0.11, 0.08)
        case (.dusk, .dark): return rgb(0.10, 0.07, 0.09)
        case (.night, .dark): return rgb(0.03, 0.05, 0.06)
        }
    }

    public static func chrome(_ phase: DayPhase, _ scheme: ColourScheme) -> RGBColour {
        let light: RGBColour
        switch phase {
        case .dawn: light = rgb(1.00, 0.96, 0.93)
        case .day: light = rgb(0.99, 0.99, 0.96)
        case .dusk: light = rgb(1.00, 0.94, 0.90)
        case .night: light = rgb(0.92, 0.94, 0.99)
        }
        return scheme == .dark ? dimmed(light, 0.12) : light
    }

    /// Resident ids that are awake in this phase; diurnal residents sleep in place at night.
    public static func awakeSet(_ phase: DayPhase) -> Set<String> {
        let all = Set(Collectible.table.map(\.id))
        switch phase {
        case .dawn, .day: return all.subtracting(nocturnal)
        case .dusk: return all
        case .night: return all.subtracting(diurnal)
        }
    }

    public static func glow(for resident: String, _ phase: DayPhase, _ scheme: ColourScheme) -> GlowSpec? {
        guard resident == mushroom else { return nil }
        let glowColour = ColourTokens.value("colour.glow", scheme) ?? rgb(0.5, 1, 0.8)
        let body = ColourTokens.value("colour.body.mushroom", scheme) ?? rgb(0.2, 0.45, 0.6)
        let intensity: Double
        switch phase {
        case .dusk: intensity = 0.7
        case .night: intensity = 1
        case .dawn, .day: intensity = 0
        }
        return GlowSpec(isOn: intensity > 0, gradient: [glowColour, body], intensity: intensity)
    }

    public static func pose(_ resident: String, _ phase: DayPhase, seed: UInt64, time: Double) -> Pose {
        if phase == .night && diurnal.contains(resident) {
            var asleep = PoseScheduler.stillPose(resident)
            asleep.anchors.eyelid = closedEyelid
            return asleep
        }
        return PoseScheduler.pose(resident, seed: seed, time: time, reduceMotion: false)
    }

    public static func stillComposition(_ phase: DayPhase, _ scheme: ColourScheme) -> SceneComposition {
        SceneComposition(
            phase: phase, sky: sky(phase, scheme), tint: tint(phase, scheme),
            light: lightDirection(phase, scheme), ground: ground(phase, scheme),
            chrome: chrome(phase, scheme),
            glow: glow(for: mushroom, phase, scheme) ?? GlowSpec(isOn: false, gradient: [], intensity: 0),
            particles: Particles.particles(0, seed: 0, phase: phase, reduceMotion: true), isStill: true)
    }
}
