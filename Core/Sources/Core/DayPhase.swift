import Foundation

/// The four phases of the day, from the device clock hour only.
public enum DayPhase: String, CaseIterable, Sendable {
    case dawn, day, dusk, night

    static let dawnHour = 5
    static let dayHour = 7
    static let duskHour = 18
    static let nightHour = 20

    public static func phase(hour: Int, minute: Int) -> DayPhase {
        switch hour {
        case dawnHour..<dayHour: return .dawn
        case dayHour..<duskHour: return .day
        case duskHour..<nightHour: return .dusk
        default: return .night
        }
    }

    public static func current(clock: any ClockService, calendar: Calendar) -> DayPhase {
        let parts = calendar.dateComponents([.hour, .minute], from: clock.now())
        return phase(hour: parts.hour ?? 12, minute: parts.minute ?? 0)
    }
}

/// The 56 pt sun and moon dial: a child's turn angle becomes a phase override.
public enum SunMoonDial {
    public static let size: Double = 56

    /// Degrees, wrapping: [0,90) dawn, [90,180) day, [180,270) dusk, [270,360) night.
    public static func phase(angle: Double) -> DayPhase {
        var turn = angle.truncatingRemainder(dividingBy: 360)
        if turn < 0 { turn += 360 }
        let all = DayPhase.allCases
        return all[min(Int(turn / 90), all.count - 1)]
    }

    /// The current phase of the two-phase dial, named for VoiceOver.
    public static func accessibilityValue(_ phase: DayPhase, _ language: Language) -> String {
        let night = phase == .night || phase == .dusk
        switch language {
        case .fr: return night ? "Nuit" : "Jour"
        case .en: return night ? "Night" : "Day"
        }
    }

    public static func accessibilityLabel(_ language: Language) -> String {
        switch language {
        case .fr: return "Cadran du soleil et de la lune : choisir le moment de la journée"
        case .en: return "Sun and moon dial: choose the time of day"
        }
    }
}
