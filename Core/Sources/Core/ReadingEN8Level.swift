/// The independently authored English text bank of the r8 level: twelve texts and thirty-six questions.
public enum EnglishTextBank {
    /// Every grapheme the English rungs teach; a segmented word may use only these.
    static let taughtGraphemes: Set<String> = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
                                               "n", "o", "p", "r", "s", "t", "u", "w", "x", "sh", "ch", "th"]
    /// The whole words an English text may use instead of segmenting them.
    static let sightWords: Set<String> = ["the", "a", "is", "has", "his", "he", "she", "we", "i", "puts", "to",
                                          "of", "was"]
    static let maximumSightShare = 0.45
    static let minimumSegmentedWords = 2

    static func word(_ text: String) -> SentenceWord {
        EnglishSentenceBank.word(text)
    }

    static func sight(_ text: String) -> SentenceWord {
        EnglishSentenceBank.sight(text)
    }

    static func sentence(_ words: [SentenceWord]) -> TextSentence {
        TextSentence(words)
    }

    static func question(_ kind: TextQuestionKind, _ prompt: String, _ choices: [String],
                         _ answerThenEvidence: Int...) -> TextQuestionItem {
        let key = TextAnswerKey(answer: answerThenEvidence[0], evidence: answerThenEvidence[1])
        return TextQuestionItem(kind: kind, prompt: prompt, choices: choices, key: key)
    }

    public static let items: [TextItem] = [henFox, catHat, dogPond, frogLog, sunShed,
                                           fishNet, chickEggs, mothShell, hillTop, catNap, sunPond, bagRug]

    public static func item(id: String) -> TextItem? {
        items.first { $0.id == id }
    }

    // MARK: the twelve texts

    static let henFox = TextItem(id: "en-r8-01", sentences: [
        sentence([sight("the"), word("red"), word("hen"), word("sat"), word("on"), sight("the"), word("nest")]),
        sentence([sight("a"), word("big"), word("fox"), word("ran"), sight("to"), sight("the"), word("hen")])
    ], questions: [
        question(.evidence, "Who sat on the nest?", ["the red hen", "the big fox"], 0, 0),
        question(.evidence, "Where did the fox run?", ["to the hen", "on the nest"], 0, 1),
        question(.inference, "Who ran to the hen?", ["the big fox", "the red hen"], 0, 1)
    ])

    static let catHat = TextItem(id: "en-r8-02", sentences: [
        sentence([sight("the"), word("big"), word("cat"), sight("has"), sight("a"), word("red"), word("hat")]),
        sentence([sight("she"), word("puts"), sight("a"), word("red"), word("hat"), word("on"), sight("the"),
                  word("big"), word("log")])
    ], questions: [
        question(.evidence, "Who has a red hat?", ["the big cat", "she"], 0, 0),
        question(.evidence, "What does she put on a log?", ["a red hat", "a big cat"], 0, 1),
        question(.inference, "Who puts a hat on a log?", ["she", "the big cat"], 0, 1)
    ])

    static let dogPond = TextItem(id: "en-r8-03", sentences: [
        sentence([sight("the"), word("dog"), word("runs"), sight("to"), sight("the"), word("big"), word("pond")]),
        sentence([sight("he"), sight("is"), word("wet"), word("and"), word("sad")])
    ], questions: [
        question(.evidence, "Who runs to the pond?", ["the dog", "he"], 0, 0),
        question(.evidence, "How is the dog?", ["wet and sad", "big"], 0, 1),
        question(.evidence, "Where does the dog run?", ["to the big pond", "wet and sad"], 0, 0)
    ])

    static let frogLog = TextItem(id: "en-r8-04", sentences: [
        sentence([sight("a"), word("frog"), word("sits"), word("on"), sight("a"), word("log")]),
        sentence([sight("the"), word("log"), sight("is"), word("in"), sight("the"), word("big"), word("pond")])
    ], questions: [
        question(.evidence, "Who sits on the log?", ["a frog", "the log"], 0, 0),
        question(.evidence, "Where is the log?", ["in the pond", "on a log"], 0, 1),
        question(.inference, "Where does the frog sit?", ["on a log", "in the pond"], 0, 0)
    ])

    static let sunShed = TextItem(id: "en-r8-05", sentences: [
        sentence([sight("the"), word("big"), word("sun"), sight("is"), word("hot")]),
        sentence([sight("we"), word("sit"), word("in"), sight("the"), word("shed")])
    ], questions: [
        question(.evidence, "What is hot?", ["the big sun", "the shed"], 0, 0),
        question(.evidence, "Where do we sit?", ["in the shed", "the big sun"], 0, 1),
        question(.evidence, "Who sits in the shed?", ["we", "the big sun"], 0, 1)
    ])

    static let fishNet = TextItem(id: "en-r8-06", sentences: [
        sentence([sight("his"), word("big"), word("fish"), sight("is"), word("in"), sight("the"), word("net")]),
        sentence([sight("he"), sight("has"), sight("a"), word("big"), word("red"), word("dish"), word("and"),
                  sight("a"), word("cup")])
    ], questions: [
        question(.evidence, "Whose fish is in the net?", ["his big fish", "he"], 0, 0),
        question(.evidence, "What does he have?", ["a big red dish", "his big fish"], 0, 1),
        question(.evidence, "Where is the fish?", ["in the net", "a big red dish"], 0, 0)
    ])

    static let chickEggs = TextItem(id: "en-r8-07", sentences: [
        sentence([sight("a"), word("chick"), word("and"), sight("a"), word("hen"), word("peck")]),
        sentence([sight("the"), word("hen"), sight("has"), word("six"), word("eggs")])
    ], questions: [
        question(.evidence, "Who pecks?", ["a chick and a hen", "six eggs"], 0, 0),
        question(.evidence, "How many eggs has the hen?", ["six eggs", "a chick"], 0, 1),
        question(.evidence, "What has the hen?", ["six eggs", "a chick and a hen"], 0, 1)
    ])

    static let mothShell = TextItem(id: "en-r8-08", sentences: [
        sentence([sight("the"), word("moth"), word("sat"), word("on"), sight("the"), word("shelf")]),
        sentence([sight("she"), sight("has"), sight("a"), word("big"), word("shell"), word("and"), sight("a"),
                  word("big"), word("moth")])
    ], questions: [
        question(.evidence, "Who sat on the shelf?", ["the moth", "she"], 0, 0),
        question(.evidence, "What has she?", ["a big shell", "the moth"], 0, 1),
        question(.inference, "Who has a shell?", ["she", "the moth"], 0, 1)
    ])

    static let hillTop = TextItem(id: "en-r8-09", sentences: [
        sentence([sight("we"), word("run"), word("up"), sight("the"), word("green"), word("hill")]),
        sentence([sight("the"), word("top"), sight("is"), word("big"), word("and"), word("steep")])
    ], questions: [
        question(.evidence, "Who runs up the hill?", ["we", "the top"], 0, 0),
        question(.evidence, "What is big and steep?", ["the top", "we"], 0, 1),
        question(.evidence, "Where do we run?", ["up the green hill", "the top"], 0, 0)
    ])

    static let catNap = TextItem(id: "en-r8-10", sentences: [
        sentence([sight("the"), word("cat"), word("can"), word("jump"), word("on"), sight("the"), word("mat")]),
        sentence([sight("his"), word("mum"), word("had"), sight("a"), word("big"), word("nap")])
    ], questions: [
        question(.evidence, "What can jump?", ["the cat", "his mum"], 0, 0),
        question(.evidence, "Who had a nap?", ["his mum", "the cat"], 0, 1),
        question(.evidence, "Where can the cat jump?", ["on the mat", "a big nap"], 0, 0)
    ])

    static let sunPond = TextItem(id: "en-r8-11", sentences: [
        sentence([sight("the"), word("sun"), sight("was"), word("hot"), word("at"), sight("the"), word("pond")]),
        sentence([sight("we"), word("got"), word("wet"), word("and"), word("had"), word("fun")])
    ], questions: [
        question(.evidence, "What was hot?", ["the sun", "we"], 0, 0),
        question(.evidence, "Who got wet?", ["we", "the sun"], 0, 1),
        question(.evidence, "Where was the sun hot?", ["at the pond", "wet and fun"], 0, 0)
    ])

    static let bagRug = TextItem(id: "en-r8-12", sentences: [
        sentence([sight("she"), sight("has"), sight("a"), word("big"), word("red"), word("bag"), word("and"),
                  sight("a"), word("hat")]),
        sentence([sight("the"), word("bag"), sight("is"), word("on"), sight("the"), word("big"), word("rug")])
    ], questions: [
        question(.evidence, "What has she?", ["a big red bag", "the bag"], 0, 0),
        question(.evidence, "Where is the bag?", ["on the big rug", "a big red bag"], 0, 1),
        question(.evidence, "Who has a hat?", ["she", "the bag"], 0, 0)
    ])
}

/// Picks three distinct texts of the English bank for a round, fixed for a seed.
public enum EnglishTextSelector {
    public static func round(seed: UInt64) -> [TextItem] {
        indices(seed: seed).map { EnglishTextBank.items[$0] }
    }

    static func indices(seed: UInt64) -> [Int] {
        TextSelector.shuffledIndices(in: EnglishTextBank.items, seed: seed &+ 0x5439)
    }
}

enum ReadingEN8Generator {
    static let configurationBase = 9000

    /// Nine items: three questions of each of the three texts picked for this seed.
    static func items(seed: UInt64) -> [Item] {
        let indices = EnglishTextSelector.indices(seed: seed)
        var out: [Item] = []
        for (roundIndex, textIndex) in indices.enumerated() {
            let text = EnglishTextBank.items[textIndex]
            for question in text.questions.indices {
                let configuration = configurationBase + textIndex * 10 + question
                // Keep the seeded choice order tied to the question's round position.
                let choiceSeed = configurationBase + roundIndex * 10 + question
                var rng = SeededRandom(seed: seed &+ 0x5239 &+ UInt64(choiceSeed))
                out.append(item(text, configuration: configuration, flip: rng.below(2)))
            }
        }
        return out.enumerated().map { index, item in item.placed(at: index + 1, of: out.count) }
    }

    static func item(_ text: TextItem, configuration: Int, flip: Int) -> Item {
        let choices = [1, 2, 3]
        var out = Item(kind: .counting, operand: choices[flip], choices: choices, correctIndex: flip)
        out.readingId = text.id
        out.iconKey = "icon.readingEN"
        out.configuration = configuration
        return out
    }

    static func allConfigurations() -> [Item] {
        var out: [Item] = []
        for (textIndex, text) in EnglishTextBank.items.enumerated() {
            for question in 0..<text.questions.count {
                out.append(item(text, configuration: configurationBase + textIndex * 10 + question, flip: 0))
            }
        }
        return out.enumerated().map { index, item in item.placed(at: index + 1, of: out.count) }
    }
}

extension Curriculum {
    /// The English text level sits directly after reading-en-r6; it waits for that level alone.
    static let readingEN8Level = LevelDefinition(
        levelId: "reading-en-r8",
        strand: "readingEN",
        titleKey: "trail.level.reading-en-r8.title",
        activity: LevelActivity(
            type: "reading-en-texts",
            generator: { ReadingEN8Generator.items(seed: $0) },
            helpSteps: TextQuestionKeys.all,
            prerequisites: ["reading-en-r6"]
        ).enumerating { ReadingEN8Generator.allConfigurations() }
    ).coded("R8")
}

extension TextTable {
    /// Title of the English text level and the spoken name of its activity.
    static let readingEN8Texts: [String: TextEntry] = [
        "trail.level.reading-en-r8.title": TextEntry("Lis l'histoire", "Read the story"),
        "activity.read-text-en.name": TextEntry("Lire un texte en anglais", "Reading an English text")
    ]
}
