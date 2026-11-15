public enum ReadingR3HelpKind: CaseIterable, Sendable {
    case bracketLetters, showSoundSlots, modelGroupedUnit
}

/// The R3 help ladder: join the letters with a bracket, show the sound slots, model the grouped unit.
public struct ReadingR3HelpLadder: Sendable {
    public static let keys = ReadingR3HelpKind.allCases.map { "reading.help.r3.\($0)" }

    public private(set) var level: Int = 0

    public init() {}

    /// The next step, or nil once all three are used. No step reveals the answer before the last.
    public mutating func advance() -> ReadingHelpStep? {
        guard level < Self.keys.count else { return nil }
        level += 1
        return ReadingHelpStep(key: Self.keys[level - 1], revealsAnswer: false)
    }

    /// The letters the bracket joins.
    public static func bracketedLetters(for item: ReadingBankItem) -> String {
        item.grapheme ?? ""
    }

    /// One sound slot per grapheme of the word, ch and ou counting as one.
    public static func soundSlotCount(for item: ReadingBankItem) -> Int {
        ReadingBank.r3Segments(item.words.first ?? "").count
    }

    public static func groupedUnit(for item: ReadingBankItem) -> String {
        item.grapheme ?? ""
    }
}

enum ReadingR3Generator {
    static let configurationBase = 3000

    static func item(_ bank: ReadingBankItem, correctIndex: Int) -> Item {
        let choices = [1, 2, 3]
        var out = Item(kind: .counting, operand: choices[correctIndex], choices: choices, correctIndex: correctIndex)
        out.readingId = bank.id
        out.configuration = configurationBase + (ReadingBank.r3Items.firstIndex(of: bank) ?? 0)
        return out
    }

    /// Five distinct R3 bank items: familiar, three current, one unfamiliar transfer.
    static func items(seed: UInt64) -> [Item] {
        var rng = SeededRandom(seed: seed &+ 0x5233)
        let order = rng.shuffled(ReadingBank.r3Items).prefix(5)
        let count = order.count
        return order.enumerated().map { index, bank in
            item(bank, correctIndex: rng.below(3)).placed(at: index + 1, of: count)
        }
    }

    static func allConfigurations() -> [Item] {
        ReadingBank.r3Items.enumerated().map { index, bank in
            item(bank, correctIndex: index % 3).placed(at: 2, of: 5)
        }
    }
}

extension Curriculum {
    static let readingR3Level = LevelDefinition(
        levelId: "reading-fr-r3",
        strand: "readingFR",
        titleKey: "trail.level.reading-fr-r3.title",
        activity: LevelActivity(
            type: "reading-words",
            generator: { ReadingR3Generator.items(seed: $0) },
            helpSteps: ReadingR3HelpLadder.keys,
            prerequisites: ["reading-fr-r2"]
        ).enumerating { ReadingR3Generator.allConfigurations() }
    ).coded("R3")
}
