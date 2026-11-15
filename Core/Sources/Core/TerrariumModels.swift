import Foundation

public enum WobbleMode: Equatable, Sendable {
    case none, animated, staticTilt
}

/// An icon-led control, always a square of at least 56 pt.
public struct TerrariumControl: Equatable, Sendable {
    public let accessibilityId: String
    public let iconKey: String
    public let labelKey: String
    public let side: Double

    public var width: Double { side }
    public var height: Double { side }
    /// The left pan arrow reuses the right-pointing play glyph, drawn mirrored.
    public var mirrorsIcon: Bool { iconKey == "icon.pan.left" }

    public init(accessibilityId: String, iconKey: String, labelKey: String, side: Double) {
        self.accessibilityId = accessibilityId
        self.iconKey = iconKey
        self.labelKey = labelKey
        self.side = max(side, ChromeIcon.minimumTarget)
    }

    public func label(_ language: Language) -> String {
        TextTable.string(labelKey, language)
    }
}

public struct NameBubble: Equatable, Sendable {
    public let iconKey: String
    public let text: String
    public let ear: TerrariumControl
}

public struct TerrariumResident: Equatable, Sendable {
    public let id: String
    public let accessibilityId: String
    public let state: CollectibleState
    public let position: GardenPoint
    public let tapArea: GardenRect
    public let isSilhouette: Bool
    public let placeholder: RingSilhouette?
    public let milestoneStars: Int?
    public let welcome: TerrariumControl?
    public let wobble: WobbleMode
    public let tapPose: Bool
    public let bubble: NameBubble?
    public let accessibilityLabel: String
}

/// A habitat is data: a later habitat is one more row, no view edit.
public struct TerrariumHabitat: Equatable, Sendable {
    public let id: String
    public let accessibilityId: String
    public let residentIds: [String]

    public func label(_ language: Language) -> String {
        TextTable.string("terrarium.habitat." + id, language)
    }
}

extension TextTable {
    static let terrariumTexts: [String: TextEntry] = [
        "terrarium.habitat.garden": TextEntry("Jardin", "Garden"),
        "terrarium.state.notArrived": TextEntry("pas encore arrivé", "not here yet"),
        "terrarium.state.ready": TextEntry("prêt à être accueilli", "ready to be welcomed"),
        "terrarium.state.met": TextEntry("accueilli", "welcomed"),
        "terrarium.milestone": TextEntry("{n} étoiles", "{n} stars"),
        "terrarium.ack": TextEntry("Bienvenue, {name} !", "Welcome, {name}!"),
        "terrarium.close.label": TextEntry("Fermer le terrarium", "Close the terrarium")
    ]
}
