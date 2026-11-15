public enum ReadingR2HelpKind: CaseIterable, Sendable {
    case segmentGraphemes, blendingPath, modelAllButFinal
}

/// The R2 help ladder: segment the graphemes, connect them with a blending path, model all but the final blend.
public struct ReadingR2HelpLadder: Sendable {
    public static let keys = ReadingR2HelpKind.allCases.map { "reading.help.r2.\($0)" }

    public private(set) var level: Int = 0

    public init() {}

    /// The next step, or nil once all three are used. No step reveals the answer.
    public mutating func advance() -> ReadingHelpStep? {
        guard level < Self.keys.count else { return nil }
        level += 1
        return ReadingHelpStep(key: Self.keys[level - 1], revealsAnswer: false)
    }

    public static func segments(for item: ReadingBankItem) -> [String] {
        item.tokens
    }

    /// Growing prefixes of the word, from the first sound up to just before the last grapheme.
    public static func blendingPath(for item: ReadingBankItem) -> [String] {
        let tokens = item.tokens
        return tokens.indices.dropLast().map { tokens[...$0].joined() }
    }

    /// Step three: every blend except the final one (the first syllable of a CVCV word, the first sound of a CV word).
    public static func modelledBlends(for item: ReadingBankItem) -> [String] {
        let path = blendingPath(for: item)
        return path.count > 1 ? Array(path.dropLast()) : path
    }
}

enum ReadingR2Generator {
    static let configurationBase = 2000

    /// A reading item for a bank item; the three choices are the three options and one is right.
    static func item(_ bank: ReadingBankItem, correctIndex: Int) -> Item {
        let choices = [1, 2, 3]
        var out = Item(kind: .counting, operand: choices[correctIndex], choices: choices, correctIndex: correctIndex)
        out.readingId = bank.id
        out.configuration = configurationBase + (ReadingBank.r2Items.firstIndex(of: bank) ?? 0)
        return out
    }

    /// Five distinct R2 bank items: familiar, three current, one unfamiliar transfer.
    static func items(seed: UInt64) -> [Item] {
        var rng = SeededRandom(seed: seed &+ 0x5232)
        let order = rng.shuffled(ReadingBank.r2Items).prefix(5)
        let count = order.count
        return order.enumerated().map { index, bank in
            item(bank, correctIndex: rng.below(3)).placed(at: index + 1, of: count)
        }
    }

    static func allConfigurations() -> [Item] {
        ReadingBank.r2Items.enumerated().map { index, bank in
            item(bank, correctIndex: index % 3).placed(at: 2, of: 5)
        }
    }
}

extension Curriculum {
    static let readingR2Level = LevelDefinition(
        levelId: "reading-fr-r2",
        strand: "readingFR",
        titleKey: "trail.level.reading-fr-r2.title",
        activity: LevelActivity(
            type: "reading-syllables",
            generator: { ReadingR2Generator.items(seed: $0) },
            helpSteps: ReadingR2HelpLadder.keys,
            prerequisites: ["reading-fr-r1"]
        ).enumerating { ReadingR2Generator.allConfigurations() }
    ).coded("R2")
}

extension TextTable {
    static let readingR2Texts: [String: TextEntry] = {
        var texts: [String: TextEntry] = [
            ReadingR2HelpLadder.keys[0]: TextEntry("Découpe le mot en lettres, une par une.",
                                                   "Split the word into its letters, one by one."),
            ReadingR2HelpLadder.keys[1]: TextEntry("Relie les sons avec un chemin : chaque lettre s'ajoute à la précédente.",
                                                   "Join the sounds along a path: each letter is added to the one before."),
            ReadingR2HelpLadder.keys[2]: TextEntry("Regarde les premiers mélanges, puis lis le dernier toi-même.",
                                                   "Watch the first blends, then read the last one yourself.")
        ]
        for item in ReadingBank.r2Items { texts[item.workedHintKey] = workedHintR2(item) }
        return texts
    }()

    private static func workedHintR2(_ item: ReadingBankItem) -> TextEntry {
        let word = item.words[0]
        let letters = item.tokens.joined(separator: ", ")
        switch item.r2Activity {
        case .decodeReveal, .none:
            return TextEntry("Exemple : lis les lettres \(letters), puis choisis le mot « \(word) ».",
                             "Example: read the letters \(letters), then pick the word “\(word)”.")
        case .changeGrapheme:
            let target = item.words.last ?? word
            return TextEntry("Exemple : change une seule lettre de « \(word) » pour faire « \(target) ».",
                             "Example: change just one letter of “\(word)” to make “\(target)”.")
        case .buildWord:
            return TextEntry("Exemple : pour « \(word) », place les lettres dans l'ordre : \(letters).",
                             "Example: for “\(word)”, put the letters in order: \(letters).")
        }
    }
}
