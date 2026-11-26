enum ReadingFR6Generator {
    static let configurationBase = 6000

    static func item(_ bank: SentenceItem, index: Int, correctIndex: Int) -> Item {
        let choices = [1, 2, 3]
        var out = Item(kind: .counting, operand: choices[correctIndex], choices: choices, correctIndex: correctIndex)
        out.readingId = bank.id
        out.iconKey = "icon.readingFR"
        out.configuration = configurationBase + index
        return out
    }

    /// Five distinct sentences of the bank; the fifth is the unfamiliar transfer of the round.
    static func items(seed: UInt64) -> [Item] {
        let round = SentenceSelector.round(seed: seed, count: 5)
        var rng = SeededRandom(seed: seed &+ 0x5236)
        let count = round.count
        return round.enumerated().map { index, bank in
            let bankIndex = FrenchSentenceBank.items.firstIndex(of: bank) ?? index
            return item(bank, index: bankIndex, correctIndex: rng.below(3)).placed(at: index + 1, of: count)
        }
    }

    static func allConfigurations() -> [Item] {
        FrenchSentenceBank.items.enumerated().map { index, bank in
            item(bank, index: index, correctIndex: index % 3).placed(at: 2, of: 5)
        }
    }
}

/// The three help steps of a sentence, in order.
enum SentenceHelpKeys {
    static let all = ["sentence.help.boundaries", "sentence.help.phrases", "sentence.help.model"]
}

extension Curriculum {
    /// The French sentence level sits directly after reading-fr-r3; it waits for that level alone.
    static let readingFR6Level = LevelDefinition(
        levelId: "reading-fr-r6",
        strand: "readingFR",
        titleKey: "trail.level.reading-fr-r6.title",
        activity: LevelActivity(
            type: "reading-sentences",
            generator: { ReadingFR6Generator.items(seed: $0) },
            helpSteps: SentenceHelpKeys.all,
            prerequisites: ["reading-fr-r3"]
        ).enumerating { ReadingFR6Generator.allConfigurations() }
    ).coded("R6")
}

extension TextTable {
    /// Titles, help steps and parent note of the French sentence level.
    static let readingFR6Texts: [String: TextEntry] = [
        "trail.level.reading-fr-r6.title": TextEntry("Lis la phrase", "Read the sentence"),
        "reading.prompt.sentence": TextEntry("Lis la phrase", "Read the sentence"),
        "reading.prompt.sentence.keyword": TextEntry("phrase", "sentence"),
        "sentence.help.boundaries": TextEntry("Sépare les mots", "Split the words"),
        "sentence.help.phrases": TextEntry("Deux groupes", "Two groups"),
        "sentence.help.model": TextEntry("Écoute le modèle", "Hear the model"),
        "sentence.blank.label": TextEntry("Mot manquant", "Missing word"),
        "sentence.hear.label": TextEntry("Écouter la phrase", "Hear the sentence"),
        "sentence.help.tap.label": TextEntry("Écouter le modèle", "Hear the model phrase"),
        "reading.parent.listened": TextEntry(
            "Une réponse écoutée n'est pas une preuve de décodage autonome : l'enfant a entendu la phrase.",
            "A listened answer is not independent decoding evidence: the child heard the sentence.")
    ]
}
