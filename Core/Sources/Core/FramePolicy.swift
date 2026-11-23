import Foundation

/// The drawing effects the render spec knows. Blur, shadow modifier and image filter exist only so the
/// allowed list can be checked never to contain them.
public enum RenderEffect: String, CaseIterable, Sendable {
    case gradientFill, opacity, offset, rotation, scale, path, glowGradient, blur, shadowModifier, imageFilter

    public var isGradient: Bool { self == .gradientFill || self == .glowGradient }
}

/// Frame rate, timeline pausing and the effects a frame may use.
public enum FramePolicy {
    public static let normalFPS = 60
    public static let lowPowerFPS = 30

    public static func targetFPS(lowPower: Bool) -> Int {
        lowPower ? lowPowerFPS : normalFPS
    }

    public static func timelinePaused(visible: Bool) -> Bool {
        !visible
    }

    /// The frame monitor never runs during an audit launch, so the audit can reach quiescence.
    public static func startsFrameMonitoring(auditState: AuditLaunchState?) -> Bool {
        auditState == nil
    }

    /// Per-frame effects: no blur, no shadow modifier, no image filter.
    public static let allowedEffects: [RenderEffect] = [
        .gradientFill, .opacity, .offset, .rotation, .scale, .path, .glowGradient
    ]

    /// Glows are drawn as gradients.
    public static let glowEffects: [RenderEffect] = [.glowGradient]

    /// Seconds between two frames at the target rate.
    public static func frameInterval(lowPower: Bool) -> Double {
        1.0 / Double(targetFPS(lowPower: lowPower))
    }
}
