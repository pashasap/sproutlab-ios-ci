public enum ActivityIconKind: Sendable, Equatable, Hashable {
    case dotCluster, tenFrameGap, joiningGroups, crossedOut, differentRows, repeatedShapes
    case soundWave, syllableBlocks, wordCard
}

public enum ActivityColourToken: Sendable, Equatable, Hashable {
    case blue, purple, teal, amber, indigo, pink
}

public struct PromptSegment: Sendable, Equatable {
    public let text: String
    public let isHighlighted: Bool
    /// The activity colour for keyword segments; nil for plain text.
    public let colourToken: ActivityColourToken?
}

/// Presentation identity of a question type: icon, colour, spoken name and highlighted prompt words.
public struct ActivityIdentity: Sendable, Equatable, Hashable {
    public let iconKind: ActivityIconKind
    public let colourToken: ActivityColourToken
    public let accessibilityNameKey: String
    let promptKey: String?
    let extraHighlights: [String]

    struct PromptSpec {
        var key: String?
        var extra: [String] = []
    }

    private init(_ icon: ActivityIconKind, _ colour: ActivityColourToken, name: String, prompt: PromptSpec) {
        iconKind = icon
        colourToken = colour
        accessibilityNameKey = "activity." + name + ".name"
        promptKey = prompt.key
        extraHighlights = prompt.extra
    }

    public static let counting = ActivityIdentity(.dotCluster, .blue, name: "counting",
                                                  prompt: PromptSpec(key: "round.prompt.count"))
    public static let makeTen = ActivityIdentity(.tenFrameGap, .purple, name: "make-ten",
                                                 prompt: PromptSpec(key: "round.prompt.bond", extra: ["10"]))
    public static let plus = ActivityIdentity(.joiningGroups, .teal, name: "plus",
                                              prompt: PromptSpec(key: "round.prompt.add"))
    public static let subtraction = ActivityIdentity(.crossedOut, .amber, name: "subtraction",
                                                     prompt: PromptSpec(key: "round.prompt.subtract"))
    /// Default is the larger question; each item picks larger or smaller through `Item.promptKey`.
    public static let comparison = ActivityIdentity(.differentRows, .indigo, name: "comparison",
                                                    prompt: PromptSpec(key: "round.prompt.larger"))
    public static let patterns = ActivityIdentity(.repeatedShapes, .pink, name: "patterns",
                                                  prompt: PromptSpec(key: "round.prompt.pattern"))

    public static let listenSound = ActivityIdentity(.soundWave, .teal, name: "reading-sounds",
                                                     prompt: PromptSpec(key: "reading.prompt.sound"))
    public static let buildSyllable = ActivityIdentity(.syllableBlocks, .purple, name: "reading-syllables",
                                                       prompt: PromptSpec(key: "reading.prompt.syllable"))
    public static let readWord = ActivityIdentity(.wordCard, .indigo, name: "reading-words",
                                                  prompt: PromptSpec(key: "reading.prompt.word"))

    public static let all: [ActivityIdentity] = [counting, makeTen, plus, subtraction, patterns, comparison,
                                                 listenSound, buildSyllable, readWord]

    public func accessibilityName(_ language: Language) -> String {
        TextTable.string(accessibilityNameKey, language)
    }

    /// Silhouette name that tells the six identities apart without colour.
    public var shapeName: String {
        switch iconKind {
        case .dotCluster: return "dot-cluster"
        case .tenFrameGap: return "frame-with-gap"
        case .joiningGroups: return "joined-groups"
        case .crossedOut: return "struck-dot"
        case .differentRows: return "unequal-rows"
        case .repeatedShapes: return "repeating-shapes"
        case .soundWave: return "sound-wave"
        case .syllableBlocks: return "syllable-blocks"
        case .wordCard: return "word-card"
        }
    }

    /// The full prompt split into segments; keywords are separate highlighted segments.
    public func promptSegments(_ language: Language) -> [PromptSegment] {
        guard let promptKey else { return [] }
        return segments(forKey: promptKey, language)
    }

    /// Splits the prompt `promptKey` around its keyword (`promptKey + ".keyword"`) in this identity's colour.
    func segments(forKey promptKey: String, _ language: Language) -> [PromptSegment] {
        let full = TextTable.string(promptKey, language)
        let keyword = TextTable.string(promptKey + ".keyword", language)
        var segments: [PromptSegment] = []
        var rest = Substring(full)
        for word in [keyword] + extraHighlights {
            guard let range = rest.range(of: word) else { continue }
            let before = rest[rest.startIndex..<range.lowerBound]
            if !before.isEmpty {
                segments.append(PromptSegment(text: String(before), isHighlighted: false, colourToken: nil))
            }
            segments.append(PromptSegment(text: word, isHighlighted: true, colourToken: colourToken))
            rest = rest[range.upperBound...]
        }
        if !rest.isEmpty {
            segments.append(PromptSegment(text: String(rest), isHighlighted: false, colourToken: nil))
        }
        return segments
    }
}

extension TextTable {
    static let activityTexts: [String: TextEntry] = [
        "activity.counting.name": TextEntry("Compter", "Counting"),
        "activity.make-ten.name": TextEntry("Faire 10", "Make ten"),
        "activity.plus.name": TextEntry("Addition", "Plus"),
        "activity.subtraction.name": TextEntry("Soustraction", "Subtraction"),
        "activity.comparison.name": TextEntry("Comparer", "Comparison"),
        "activity.patterns.name": TextEntry("Suites", "Patterns"),
        "activity.reading-sounds.name": TextEntry("Écouter les sons", "Listening to sounds"),
        "activity.reading-syllables.name": TextEntry("Assembler des syllabes", "Building syllables"),
        "activity.reading-words.name": TextEntry("Découvrir des mots", "Discovering words")
    ]
}

extension LevelDefinition {
    /// Identities of the activities this level plays, shown on its tile.
    public var activityIdentities: [ActivityIdentity] {
        switch activityType {
        case "counting-and-bonds": return [.counting, .makeTen]
        case "add-and-subtract": return [.plus, .subtraction]
        case "patterns-and-comparison": return [.patterns, .comparison]
        case "reading-sounds": return [.listenSound]
        case "reading-syllables": return [.buildSyllable]
        case "reading-words": return [.readWord]
        default: return []
        }
    }
}
