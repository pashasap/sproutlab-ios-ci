enum ReadingFR8Generator {
    static let configurationBase = 8000

    /// Nine items: three questions of each of the three texts picked for this seed.
    static func items(seed: UInt64) -> [Item] {
        let indices = TextSelector.indices(seed: seed)
        var out: [Item] = []
        for (roundIndex, textIndex) in indices.enumerated() {
            let text = FrenchTextBank.items[textIndex]
            for question in text.questions.indices {
                let configuration = configurationBase + textIndex * 10 + question
                // Keep the seeded choice order tied to the question's round position.
                let choiceSeed = configurationBase + roundIndex * 10 + question
                var rng = SeededRandom(seed: seed &+ 0x5238 &+ UInt64(choiceSeed))
                out.append(item(text, configuration: configuration, flip: rng.below(2)))
            }
        }
        return out.enumerated().map { index, item in item.placed(at: index + 1, of: out.count) }
    }

    static func item(_ text: TextItem, configuration: Int, flip: Int) -> Item {
        let choices = [1, 2, 3]
        var out = Item(kind: .counting, operand: choices[flip], choices: choices, correctIndex: flip)
        out.readingId = text.id
        out.iconKey = "icon.readingFR"
        out.configuration = configuration
        return out
    }

    static func allConfigurations() -> [Item] {
        var out: [Item] = []
        for (textIndex, text) in FrenchTextBank.items.enumerated() {
            for question in 0..<text.questions.count {
                out.append(item(text, configuration: configurationBase + textIndex * 10 + question, flip: 0))
            }
        }
        return out.enumerated().map { index, item in item.placed(at: index + 1, of: out.count) }
    }
}

/// The three help keys of a text question, in order.
enum TextQuestionKeys {
    static let all = ["text.help.evidence", "text.help.link", "text.help.show"]
}

extension Curriculum {
    /// The French text level sits directly after reading-fr-r6; it waits for that level alone.
    static let readingFR8Level = LevelDefinition(
        levelId: "reading-fr-r8",
        strand: "readingFR",
        titleKey: "trail.level.reading-fr-r8.title",
        activity: LevelActivity(
            type: "reading-texts",
            generator: { ReadingFR8Generator.items(seed: $0) },
            helpSteps: TextQuestionKeys.all,
            prerequisites: ["reading-fr-r6"]
        ).enumerating { ReadingFR8Generator.allConfigurations() }
    ).coded("R8")
}

extension TextTable {
    /// Titles, prompts, help steps and the parent note of the French text level.
    static let readingFR8Texts: [String: TextEntry] = [
        "trail.level.reading-fr-r8.title": TextEntry("Lis le texte", "Read the text"),
        "reading.prompt.text": TextEntry("Lis le texte", "Read the text"),
        "reading.prompt.text.keyword": TextEntry("texte", "text"),
        "text.help.evidence": TextEntry("Cherche la phrase", "Find the sentence"),
        "text.help.link": TextEntry("Relie le nom", "Link the name"),
        "text.help.show": TextEntry("Montre la phrase", "Show the sentence"),
        "text.hear.label": TextEntry("Écouter le texte", "Hear the whole text"),
        "activity.read-text.name": TextEntry("Lire un texte", "Reading a text"),
        "text.parent.listened": TextEntry(
            "Une réponse écoutée n'est pas une preuve de décodage autonome : l'enfant a entendu tout le texte.",
            "A listened answer is not independent decoding evidence: the child heard the whole text.")
    ]
}
