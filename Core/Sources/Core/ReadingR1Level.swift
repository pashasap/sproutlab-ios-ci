public struct ReadingHelpStep: Equatable, Sendable {
    public let key: String
    public let revealsAnswer: Bool
}

/// The R1 help ladder: reveal the sound slots, align the graphemes, demonstrate the first blend.
public struct ReadingHelpLadder: Sendable {
    public static let keys = ["reading.help.r1.revealSoundSlots", "reading.help.r1.alignGraphemes",
                              "reading.help.r1.demonstrateFirstBlend"]

    public private(set) var level: Int = 0

    public init() {}

    /// The next step, or nil once all three are used. Only the last step shows the first blend.
    public mutating func advance() -> ReadingHelpStep? {
        guard level < Self.keys.count else { return nil }
        level += 1
        return ReadingHelpStep(key: Self.keys[level - 1], revealsAnswer: level == Self.keys.count)
    }
}

enum ReadingR1Generator {
    static let configurationBase = 1000

    /// A reading item for a bank item; the three choices are the three options and one is right.
    /// The carrier stimulus shows the right option's number, so the drawn meaning never contradicts it.
    static func item(_ bank: ReadingBankItem, correctIndex: Int) -> Item {
        let choices = [1, 2, 3]
        var out = Item(kind: .counting, operand: choices[correctIndex], choices: choices, correctIndex: correctIndex)
        out.readingId = bank.id
        out.configuration = configurationBase + (ReadingBank.r1Items.firstIndex(of: bank) ?? 0)
        return out
    }

    /// Five distinct bank items: familiar, three current, one unfamiliar transfer.
    static func items(seed: UInt64) -> [Item] {
        var rng = SeededRandom(seed: seed &+ 0x5231)
        let order = rng.shuffled(ReadingBank.r1Items).prefix(5)
        let count = order.count
        return order.enumerated().map { index, bank in
            item(bank, correctIndex: rng.below(3)).placed(at: index + 1, of: count)
        }
    }

    static func allConfigurations() -> [Item] {
        ReadingBank.r1Items.enumerated().map { index, bank in
            item(bank, correctIndex: index % 3).placed(at: 2, of: 5)
        }
    }
}

extension Curriculum {
    static let readingR1Level = LevelDefinition(
        levelId: "reading-fr-r1",
        strand: "readingFR",
        titleKey: "trail.level.reading-fr-r1.title",
        activity: LevelActivity(
            type: "reading-sounds",
            generator: { ReadingR1Generator.items(seed: $0) },
            helpSteps: ReadingHelpLadder.keys,
            prerequisites: []
        ).enumerating { ReadingR1Generator.allConfigurations() }
    ).coded("R1")
}

extension TextTable {
    static let readingR1Texts: [String: TextEntry] = {
        var texts: [String: TextEntry] = [
            ReadingHelpLadder.keys[0]: TextEntry("Regarde les cases : une case pour chaque son.",
                                                 "Look at the boxes: one box for each sound."),
            ReadingHelpLadder.keys[1]: TextEntry("Aligne chaque lettre sous sa case, dans l'ordre.",
                                                 "Line up each letter under its box, in order."),
            ReadingHelpLadder.keys[2]: TextEntry("Regarde le premier mélange : les deux sons s'enchaînent.",
                                                 "Watch the first blend: the two sounds run together.")
        ]
        for item in ReadingBank.r1Items { texts[item.workedHintKey] = workedHint(item) }
        return texts
    }()

    private static func workedHint(_ item: ReadingBankItem) -> TextEntry {
        let word = item.speechItem.text
        let letters = item.tokens.joined(separator: ", ")
        switch item.activity {
        case .tapGrapheme:
            let grapheme = item.grapheme ?? ""
            return TextEntry("Exemple : dans « \(word) », on entend la lettre « \(grapheme) ». Touche-la.",
                             "Example: in “\(word)”, you hear the letter “\(grapheme)”. Tap it.")
        case .sequenceSounds:
            return TextEntry("Exemple : pour « \(word) », place les lettres dans l'ordre : \(letters).",
                             "Example: for “\(word)”, put the letters in order: \(letters).")
        case .blendNew:
            return TextEntry("Exemple : \(letters) s'enchaînent et font « \(word) ».",
                             "Example: \(letters) run together and make “\(word)”.")
        }
    }
}
