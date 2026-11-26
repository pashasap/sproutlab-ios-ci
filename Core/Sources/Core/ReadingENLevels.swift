enum ReadingENGenerator {
    static let configurationBase = 3000

    /// A reading item for a bank item; the three choices are the three options and one is right.
    static func item(_ bank: ReadingENItem, correctIndex: Int) -> Item {
        let choices = [1, 2, 3]
        var out = Item(kind: .counting, operand: choices[correctIndex], choices: choices, correctIndex: correctIndex)
        out.readingId = bank.id
        out.iconKey = "icon.readingEN"
        out.configuration = configurationBase + (ReadingENBank.allItems.firstIndex(of: bank) ?? 0)
        return out
    }

    /// Five distinct items of the rung, in a fixed order for a given seed.
    static func items(rung: ReadingENRung, seed: UInt64) -> [Item] {
        var rng = SeededRandom(seed: seed &+ 0x454E)
        let order = rng.shuffled(ReadingENBank.items(rung: rung)).prefix(5)
        let count = order.count
        return order.enumerated().map { index, bank in
            item(bank, correctIndex: rng.below(3)).placed(at: index + 1, of: count)
        }
    }

    static func allConfigurations(rung: ReadingENRung) -> [Item] {
        ReadingENBank.items(rung: rung).enumerated().map { index, bank in
            item(bank, correctIndex: index % 3).placed(at: 2, of: 5)
        }
    }
}

extension Curriculum {
    private static func readingENLevel(_ rung: ReadingENRung, type: String, after: String?) -> LevelDefinition {
        LevelDefinition(
            levelId: rung.levelId,
            strand: "readingEN",
            titleKey: "trail.level.\(rung.levelId).title",
            activity: LevelActivity(
                type: type,
                generator: { ReadingENGenerator.items(rung: rung, seed: $0) },
                helpSteps: ReadingENHelpLadder.levelKeys(rung),
                prerequisites: after.map { [$0] } ?? []
            ).enumerating { ReadingENGenerator.allConfigurations(rung: rung) }
        ).coded(rung.rawValue.uppercased())
    }

    static let readingENLevels: [LevelDefinition] = [
        readingENLevel(.en1, type: "reading-en-sounds", after: nil),
        readingENLevel(.en2, type: "reading-en-words", after: ReadingENRung.en1.levelId),
        readingENLevel(.en3, type: "reading-en-digraphs", after: ReadingENRung.en2.levelId),
        readingEN6Level,
        readingEN8Level
    ]

    static let readingENTitleKeys = ReadingENRung.allCases.map { "trail.level.\($0.levelId).title" }
        + ["trail.level.reading-en-r6.title", "trail.level.reading-en-r8.title"]
}
