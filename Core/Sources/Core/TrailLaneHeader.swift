/// The header drawn above one trail lane: a text key and an allow-listed SF Symbol.
public struct TrailLaneHeader: Sendable, Equatable {
    public let titleKey: String
    public let symbolName: String
    /// The language the header was built for; `title` is read in it.
    public let language: Language

    /// Title in the language the header was built for.
    public var title: String { title(language) }

    public func title(_ language: Language) -> String { TextTable.string(titleKey, language) }
}

public enum TrailLaneHeaders {
    static let mathKey = "lane.math.title"
    static let readingKey = "icon.readingFR.label"

    public static func header(forTrack track: String, language: Language) -> TrailLaneHeader {
        switch track {
        case "readingFR":
            return TrailLaneHeader(titleKey: readingKey, symbolName: "book.fill", language: language)
        case "readingEN":
            return TrailLaneHeader(titleKey: "icon.readingEN.label", symbolName: "book.fill", language: language)
        case "robot":
            return TrailLaneHeader(titleKey: "track.robot.name", symbolName: "leaf.fill", language: language)
        case "music":
            return TrailLaneHeader(titleKey: "track.music.name",
                                   symbolName: ChromeCatalog.symbolName(for: .note), language: language)
        default:
            return TrailLaneHeader(titleKey: mathKey, symbolName: "number", language: language)
        }
    }
}

extension TextTable {
    static let laneTexts: [String: TextEntry] = [
        "lane.math.title": TextEntry("Mathématiques", "Math")
    ]
}
