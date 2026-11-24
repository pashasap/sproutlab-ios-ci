public enum ActivityIconKind: Sendable, Equatable, Hashable {
    case dotCluster, tenFrameGap, joiningGroups, crossedOut, differentRows, repeatedShapes
    case soundWave, syllableBlocks, wordCard
    case orderedTiles, blendedSounds, swappedLetter, letterPair, joinedWord, mendedWord
}

public enum ActivityColourToken: Sendable, Equatable, Hashable, CaseIterable {
    case blue, purple, teal, amber, indigo, pink
    case red, green, orange, brown, cyan, magenta, slate, gold, lime
}

/// Light and dark value of every activity colour token; the app renders these values.
public enum ActivityPalette {
    private static func hex(_ value: UInt32) -> RGBColour {
        RGBColour(r: Double((value >> 16) & 0xFF) / 255, g: Double((value >> 8) & 0xFF) / 255,
                  b: Double(value & 0xFF) / 255)
    }

    private static func pair(_ token: ActivityColourToken) -> (light: UInt32, dark: UInt32) {
        switch token {
        case .blue: return (0x1F5FBF, 0x8AB8FF)
        case .purple: return (0x7B3FBF, 0xC9A2FF)
        case .teal: return (0x0F766E, 0x6FD6CB)
        case .amber: return (0x9A5B00, 0xFFC247)
        case .indigo: return (0x4338CA, 0xA5A0FF)
        case .pink: return (0xB0306F, 0xFF9CC6)
        case .red: return (0xB3261E, 0xFF8A80)
        case .green: return (0x2E7D32, 0x81C784)
        case .orange: return (0xC2410C, 0xFDBA74)
        case .brown: return (0x6D4C41, 0xBCAAA4)
        case .cyan: return (0x0E7490, 0x67E8F9)
        case .magenta: return (0xA21CAF, 0xF0ABFC)
        case .slate: return (0x475569, 0xCBD5E1)
        case .gold: return (0x8A6D00, 0xFDE047)
        case .lime: return (0x4D7C0F, 0xBEF264)
        }
    }

    public static func colour(_ token: ActivityColourToken, _ scheme: ColourScheme) -> RGBColour {
        let values = pair(token)
        return hex(scheme == .light ? values.light : values.dark)
    }
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

    public static let listenSound = ActivityIdentity(.soundWave, .red, name: "reading-sounds",
                                                     prompt: PromptSpec(key: "reading.prompt.sound"))
    public static let buildSyllable = ActivityIdentity(.syllableBlocks, .magenta, name: "reading-syllables",
                                                       prompt: PromptSpec(key: "reading.prompt.syllable"))
    public static let readWord = ActivityIdentity(.wordCard, .brown, name: "reading-words",
                                                  prompt: PromptSpec(key: "reading.prompt.word"))
    public static let orderSounds = ActivityIdentity(.orderedTiles, .green, name: "reading-order",
                                                     prompt: PromptSpec(key: "reading.prompt.order"))
    public static let blendSounds = ActivityIdentity(.blendedSounds, .orange, name: "reading-blend",
                                                     prompt: PromptSpec(key: "reading.prompt.blend"))
    public static let changeLetter = ActivityIdentity(.swappedLetter, .cyan, name: "reading-change",
                                                      prompt: PromptSpec(key: "reading.prompt.change"))
    public static let findPair = ActivityIdentity(.letterPair, .slate, name: "reading-pair",
                                                  prompt: PromptSpec(key: "reading.prompt.digraph"))
    public static let blendWord = ActivityIdentity(.joinedWord, .gold, name: "reading-join",
                                                   prompt: PromptSpec(key: "reading.prompt.blendword"))
    public static let repairWord = ActivityIdentity(.mendedWord, .lime, name: "reading-repair",
                                                    prompt: PromptSpec(key: "reading.prompt.repair"))

    public static let all: [ActivityIdentity] = [counting, makeTen, plus, subtraction, patterns, comparison,
                                                 listenSound, buildSyllable, readWord, orderSounds, blendSounds,
                                                 changeLetter, findPair, blendWord, repairWord]

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
        case .orderedTiles: return "ordered-tiles"
        case .blendedSounds: return "blended-sounds"
        case .swappedLetter: return "swapped-letter"
        case .letterPair: return "letter-pair"
        case .joinedWord: return "joined-word"
        case .mendedWord: return "mended-word"
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
        "activity.reading-words.name": TextEntry("Découvrir des mots", "Discovering words"),
        "activity.reading-order.name": TextEntry("Mettre les sons dans l'ordre", "Putting sounds in order"),
        "activity.reading-blend.name": TextEntry("Mélanger les sons", "Blending sounds"),
        "activity.reading-change.name": TextEntry("Changer une lettre", "Changing a letter"),
        "activity.reading-pair.name": TextEntry("Trouver un groupe de lettres", "Finding a letter pair"),
        "activity.reading-join.name": TextEntry("Lire un mot", "Reading a word"),
        "activity.reading-repair.name": TextEntry("Réparer un mot", "Mending a word"),
        // Short child-path prompts of the new reading kinds (1 to 3 words) with their keywords.
        "reading.prompt.order": TextEntry("Mets en ordre", "Put in order"),
        "reading.prompt.order.keyword": TextEntry("ordre", "order"),
        "reading.prompt.blend": TextEntry("Mélange les sons", "Blend the sounds"),
        "reading.prompt.blend.keyword": TextEntry("Mélange", "Blend"),
        "reading.prompt.change": TextEntry("Change la lettre", "Change the letter"),
        "reading.prompt.change.keyword": TextEntry("Change", "Change"),
        "reading.prompt.digraph": TextEntry("Cherche le groupe", "Find the pair"),
        "reading.prompt.digraph.keyword": TextEntry("groupe", "pair"),
        "reading.prompt.blendword": TextEntry("Lis le mot", "Read the word"),
        "reading.prompt.blendword.keyword": TextEntry("Lis", "Read"),
        "reading.prompt.repair": TextEntry("Répare le mot", "Fix the word"),
        "reading.prompt.repair.keyword": TextEntry("Répare", "Fix"),
        // The sentence Tap to Hear adds after the short prompt; never shown on the child path.
        "round.speech.count": TextEntry("Compte les points que tu vois.", "Count the dots you can see."),
        "round.speech.bond": TextEntry("Combien de points faut-il pour faire 10 ?", "How many more dots make 10?"),
        "round.speech.add": TextEntry("Combien de points y a-t-il en tout dans les deux groupes ?",
                                        "How many dots are there in total in both groups?"),
        "round.speech.subtract": TextEntry("Combien de points restent-ils ?", "How many dots are left?"),
        "round.speech.pattern": TextEntry("Quel nombre manque dans la suite ?",
                                          "Which number is missing in the pattern?"),
        "round.speech.larger": TextEntry("Touche la quantité la plus grande.", "Tap the larger quantity."),
        "round.speech.smaller": TextEntry("Touche la quantité la plus petite.", "Tap the smaller quantity."),
        "reading.speech.sound": TextEntry("Écoute bien, puis touche la lettre du son.",
                                          "Listen to the sound and tap the letter."),
        "reading.speech.syllable": TextEntry("Assemble les lettres pour faire la syllabe.",
                                             "Put the letters together to make the syllable."),
        "reading.speech.word": TextEntry("Touche le mot que tu entends.", "Tap the word you hear."),
        "reading.speech.order": TextEntry("Écoute et mets les sons dans l'ordre.",
                                          "Listen and put the sounds in order."),
        "reading.speech.blend": TextEntry("Écoute et mélange les sons pour dire le mot.",
                                          "Listen and blend the sounds to say the word."),
        "reading.speech.change": TextEntry("Change une lettre pour faire un nouveau mot.",
                                           "Change one letter to make a new word."),
        "reading.speech.digraph": TextEntry("Trouve le groupe de lettres qui fait le son.",
                                            "Find the group of letters that makes the sound."),
        "reading.speech.blendword": TextEntry("Place les lettres pour lire le mot.",
                                              "Place the letters to read the word."),
        "reading.speech.repair": TextEntry("Recolle les morceaux pour réparer le mot.",
                                           "Put the pieces back to fix the word."),
        "reading.choice.label": TextEntry("Lettre", "Letter"),
        "reading.tile.position": TextEntry("Position %1", "Place %1"),
        "reading.slot.empty": TextEntry("Case %1 vide", "Empty slot %1")
    ]
}

extension LevelDefinition {
    /// Identities of the activities this level plays, shown on its tile.
    public var activityIdentities: [ActivityIdentity] {
        switch activityType {
        case "counting-and-bonds": return [.counting, .makeTen]
        case "add-and-subtract": return [.plus, .subtraction]
        case "patterns-and-comparison": return [.patterns, .comparison]
        case "reading-sounds": return [.listenSound, .orderSounds, .blendSounds]
        case "reading-syllables": return [.readWord, .changeLetter, .buildSyllable]
        case "reading-words": return [.findPair, .blendWord, .repairWord]
        default: return []
        }
    }
}
