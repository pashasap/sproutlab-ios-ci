/// The independently authored English sentence bank of the r6 level: 24 sentences, eight of each kind.
public enum EnglishSentenceBank {
    /// The English digraphs a sentence word may use; every other letter is read on its own.
    static let multiLetterGraphemes = ["sh", "ch", "th"]

    /// Splits a spelling into its graphemes, taught digraphs first; the joined graphemes spell the word.
    static func graphemes(of text: String) -> [String] {
        let letters = Array(text.lowercased())
        var out: [String] = []
        var index = 0
        while index < letters.count {
            if index + 1 < letters.count {
                let pair = String(letters[index...index + 1])
                if multiLetterGraphemes.contains(pair) {
                    out.append(pair)
                    index += 2
                    continue
                }
            }
            out.append(String(letters[index]))
            index += 1
        }
        return out
    }

    static func word(_ text: String) -> SentenceWord {
        SentenceWord(text: text, graphemes: graphemes(of: text), isSight: false)
    }

    /// Sight words are read whole and carry no graphemes.
    static func sight(_ text: String) -> SentenceWord {
        SentenceWord(text: text, graphemes: [], isSight: true)
    }

    static func item(_ number: Int, _ kind: SentenceKind, _ words: [SentenceWord]) -> SentenceItem {
        SentenceItem(id: String(format: "en-r6-%02d", number), kind: kind, words: words)
    }

    public static let items: [SentenceItem] = complete + scene + order

    /// Complete the sentence: the child picks the word that fills the blank.
    static let complete: [SentenceItem] = [
        item(1, .complete, [sight("the"), word("red"), word("hen"), word("sat"), sight("on"), sight("a"),
                            word("mat")]),
        item(2, .complete, [sight("a"), word("big"), word("dog"), word("ran"), sight("to"), sight("the"),
                            word("log")]),
        item(3, .complete, [sight("the"), word("cat"), word("had"), sight("a"), word("nap")]),
        item(4, .complete, [sight("the"), word("fox"), word("can"), word("run"), word("up"), sight("the"),
                            word("hill")]),
        item(5, .complete, [sight("a"), word("hen"), word("and"), sight("a"), word("chick"), word("sit")]),
        item(6, .complete, [sight("a"), word("pup"), word("can"), word("dig"), sight("in"), sight("the"),
                            word("mud")]),
        item(7, .complete, [sight("the"), word("cat"), word("sat"), sight("on"), sight("the"), word("big"),
                            word("bed")]),
        item(8, .complete, [sight("a"), word("red"), word("hen"), word("and"), sight("a"), word("duck"),
                            word("sat")])
    ]

    /// Pick the scene: both scenes share their objects and differ in one sentence-named detail.
    static let scene: [SentenceItem] = [
        item(9, .scene, [sight("the"), word("red"), word("hen"), word("sat"), sight("on"), sight("the"),
                         word("mat")]),
        item(10, .scene, [sight("a"), word("big"), word("dog"), word("can"), word("dig")]),
        item(11, .scene, [sight("the"), word("wet"), word("pup"), word("ran"), sight("in"), sight("the"),
                          word("mud")]),
        item(12, .scene, [sight("the"), word("cat"), word("sat"), sight("on"), sight("the"), word("hot"),
                          word("rug")]),
        item(13, .scene, [sight("a"), word("fat"), word("hen"), word("sits"), sight("on"), sight("the"),
                          word("box")]),
        item(14, .scene, [sight("the"), word("big"), word("duck"), word("swam"), sight("in"), sight("the"),
                          word("pond")]),
        item(15, .scene, [sight("the"), word("red"), word("hen"), word("pecks"), sight("in"), sight("the"),
                          word("mud")]),
        item(16, .scene, [sight("the"), word("hot"), word("sun"), word("is"), word("up")])
    ]

    /// Put the words in order: every sentence has two to five distinct words.
    static let order: [SentenceItem] = [
        item(17, .order, [sight("the"), word("hen"), word("sat")]),
        item(18, .order, [sight("a"), word("dog"), word("can"), word("dig")]),
        item(19, .order, [sight("the"), word("red"), word("hen"), word("ran")]),
        item(20, .order, [sight("a"), word("big"), word("duck"), word("swam")]),
        item(21, .order, [word("pup"), word("sits")]),
        item(22, .order, [word("mud"), word("gets"), word("wet")]),
        item(23, .order, [sight("a"), word("hen"), word("can"), word("peck")]),
        item(24, .order, [sight("the"), word("big"), word("dog"), word("ran")])
    ]

    public static func item(id: String) -> SentenceItem? {
        items.first { $0.id == id }
    }
}

extension SentenceDecodability {
    /// Every grapheme the English reading rungs EN1 to EN3 teach; the French rungs do not define it.
    public static let englishTaughtGraphemes: Set<String> = ReadingENCorrespondences.taught(upTo: .en3)

    /// The whole English words a sentence may use instead of segmenting them.
    public static let englishSightWords: Set<String> = ["the", "a", "is", "in", "on", "to"]

    /// The decodability check of an English sentence: an empty result means the sentence passes.
    public static func checkEnglish(_ item: SentenceItem) -> [String] {
        var findings: [String] = []
        if item.words.isEmpty { return ["empty sentence"] }
        findings += item.words.flatMap { englishWordFindings($0, id: item.id) }
        let sight = item.words.filter(\.isSight).count
        if Double(sight) > maximumSightShare * Double(item.words.count) {
            findings.append("\(item.id): sight share above limit")
        }
        let segmented = item.words.filter { !$0.isSight && !$0.graphemes.isEmpty }.count
        if segmented < minimumSegmentedWords {
            findings.append("\(item.id): fewer than two segmented words")
        }
        if item.sentence != item.words.map(\.text).joined(separator: " ") {
            findings.append("\(item.id): sentence does not join its words")
        }
        return findings
    }

    static func englishWordFindings(_ word: SentenceWord, id: String) -> [String] {
        if word.isSight {
            return englishSightWords.contains(word.text.lowercased())
                ? [] : ["\(id): unlisted sight word \(word.text)"]
        }
        if word.graphemes.isEmpty { return ["\(id): segmented word \(word.text) has no graphemes"] }
        var findings: [String] = []
        for token in word.graphemes {
            if token.hasPrefix("~") {
                let letter = String(token.dropFirst()).lowercased()
                if !englishTaughtGraphemes.contains(letter) { findings.append("\(id): silent letter \(token)") }
            } else if !englishTaughtGraphemes.contains(token.lowercased()) {
                findings.append("\(id): untaught grapheme \(token)")
            }
        }
        let joined = word.graphemes.map { $0.replacingOccurrences(of: "~", with: "") }.joined()
        if joined.lowercased() != word.text.lowercased() {
            findings.append("\(id): graphemes do not spell \(word.text)")
        }
        return findings
    }
}

enum ReadingEN6Generator {
    static let configurationBase = 7000

    static func item(_ bank: SentenceItem, index: Int, correctIndex: Int) -> Item {
        let choices = [1, 2, 3]
        var out = Item(kind: .counting, operand: choices[correctIndex], choices: choices, correctIndex: correctIndex)
        out.readingId = bank.id
        out.iconKey = "icon.readingEN"
        out.configuration = configurationBase + index
        return out
    }

    /// Five distinct English sentences; the fifth is the unfamiliar transfer of the round.
    static func items(seed: UInt64) -> [Item] {
        let round = SentenceSelector.round(seed: seed, count: 5, language: .en)
        var rng = SeededRandom(seed: seed &+ 0x5236)
        let count = round.count
        return round.enumerated().map { index, bank in
            let bankIndex = EnglishSentenceBank.items.firstIndex(of: bank) ?? index
            return item(bank, index: bankIndex, correctIndex: rng.below(3)).placed(at: index + 1, of: count)
        }
    }

    static func allConfigurations() -> [Item] {
        EnglishSentenceBank.items.enumerated().map { index, bank in
            item(bank, index: index, correctIndex: index % 3).placed(at: 2, of: 5)
        }
    }
}

extension Curriculum {
    /// The English sentence level sits directly after reading-en-en3; it waits for that level alone.
    static let readingEN6Level = LevelDefinition(
        levelId: "reading-en-r6",
        strand: "readingEN",
        titleKey: "trail.level.reading-en-r6.title",
        activity: LevelActivity(
            type: "reading-en-sentences",
            generator: { ReadingEN6Generator.items(seed: $0) },
            helpSteps: SentenceHelpKeys.all,
            prerequisites: ["reading-en-en3"]
        ).enumerating { ReadingEN6Generator.allConfigurations() }
    ).coded("R6")
}

extension TextTable {
    /// Title of the English sentence level; its activity name lives in the activity table.
    static let readingEN6Texts: [String: TextEntry] = [
        "trail.level.reading-en-r6.title": TextEntry("Phrase en anglais", "English sentence")
    ]
}
