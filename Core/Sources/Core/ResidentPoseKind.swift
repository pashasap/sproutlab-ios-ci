import Foundation

/// The coarse pose of a met resident: awake or active by day, resting or glowing by night.
public enum ResidentPoseKind: Equatable, Sendable {
    case awake, active, resting, glowing

    /// Day: active for residents awake by day, else awake. Night: glowing for residents awake at night, else resting.
    public static func pose(_ id: String, _ phase: DayPhase) -> ResidentPoseKind {
        let night = phase == .night || phase == .dusk
        if night { return SkyPalette.awakeSet(.night).contains(id) ? .glowing : .resting }
        return SkyPalette.awakeSet(.day).contains(id) ? .active : .awake
    }
}
