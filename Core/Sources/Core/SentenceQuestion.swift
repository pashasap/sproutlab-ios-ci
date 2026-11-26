/// Everything the view draws for one sentence question: the sentence with its single blank, exactly three
/// word choices, the whole-sentence speech text with its language, and the three help steps.
/// The value is built from the item alone, so it exists before the first frame and never changes with help.
public struct SentenceQuestion: Sendable, Equatable {
    /// The sentence words in reading order; the missing word is `SentencePresentation.blankToken`.
    public let words: [String]
    /// Position of `words` that is drawn as the blank.
    public let blankIndex: Int
    /// The three offered words, in the order they are drawn.
    public let choices: [String]
    /// Index of `choices` that is the right word.
    public let correctChoiceIndex: Int
    /// The whole sentence with the blank filled, spoken only on an explicit tap.
    public let speechText: String
    /// French for the French sentence bank, English for the English one.
    public let speechLanguage: Language
    /// Exactly three steps; none of them changes the answer.
    public let helpSteps: [HelpStepPresentation]
    public let promptText: String
    public let blankLabel: String
    public let hearLabel: String

    /// The answered word, or nil when there is no valid choice.
    public var correctChoice: String {
        choices.indices.contains(correctChoiceIndex) ? choices[correctChoiceIndex] : ""
    }

    /// The voice tag of the sentence's own language.
    public var voiceTag: String {
        speechLanguage == .fr ? "fr-FR" : "en-GB"
    }

    /// The bundled values of one question, so no initialiser grows past a handful of parameters.
    struct Parts {
        let words: [String]
        let blankIndex: Int
        let choices: [String]
        let correctChoiceIndex: Int
        let help: SpeechAndHelp
    }

    struct SpeechAndHelp {
        let speechText: String
        let language: Language
        let helpSteps: [HelpStepPresentation]
        let promptText: String
        let blankLabel: String
        let hearLabel: String
    }

    init(parts: Parts) {
        words = parts.words
        blankIndex = parts.blankIndex
        choices = parts.choices
        correctChoiceIndex = parts.correctChoiceIndex
        speechText = parts.help.speechText
        speechLanguage = parts.help.language
        helpSteps = parts.help.helpSteps
        promptText = parts.help.promptText
        blankLabel = parts.help.blankLabel
        hearLabel = parts.help.hearLabel
    }
}

/// Builds the sentence question of a reading item: a pure function of the item and its level.
public enum SentenceQuestions {
    public static func question(item: Item, levelId: String) -> SentenceQuestion? {
        guard let bank = bankItem(item) else { return nil }
        let texts = bank.item.words.map(\.text)
        guard texts.count >= 3, texts.allSatisfy({ !$0.isEmpty }) else { return nil }
        let blank = blankIndex(of: bank, seed: UInt64(item.configuration))
        var shown = texts
        shown[blank] = SentencePresentation.blankToken
        let correct = texts[blank]
        let correctIndex = min(max(item.correctIndex, 0), 2)
        let choices = choiceLabels(correct: correct, correctIndex: correctIndex,
                                   language: bank.language, seed: UInt64(item.configuration))
        return SentenceQuestion(parts: SentenceQuestion.Parts(
            words: shown,
            blankIndex: blank,
            choices: choices,
            correctChoiceIndex: correctIndex,
            help: SentenceQuestion.SpeechAndHelp(
                speechText: texts.joined(separator: " "),
                language: bank.language,
                helpSteps: HelpLadder.steps(item: item, levelId: levelId, language: bank.language),
                promptText: TextTable.string("reading.prompt.sentence", bank.language),
                blankLabel: TextTable.string("sentence.blank.label", bank.language),
                hearLabel: TextTable.string("sentence.hear.label", bank.language))))
    }

    private struct BankSentence {
        let item: SentenceItem
        let language: Language
    }

    private static func bankItem(_ item: Item) -> BankSentence? {
        guard let id = item.readingId else { return nil }
        if let french = FrenchSentenceBank.item(id: id) { return BankSentence(item: french, language: .fr) }
        if let english = EnglishSentenceBank.item(id: id) { return BankSentence(item: english, language: .en) }
        return nil
    }

    /// The blank prefers a word that is read by decoding, never a whole sight word when another exists.
    private static func blankIndex(of bank: BankSentence, seed: UInt64) -> Int {
        var rng = SeededRandom(seed: seed &+ 0x424C)
        let decoded = bank.item.words.indices.filter { !bank.item.words[$0].isSight }
        let pool = decoded.isEmpty ? Array(bank.item.words.indices) : decoded
        return pool[rng.below(pool.count)]
    }

    /// The right word at `correctIndex` plus two distinct words of the same language bank.
    private static func choiceLabels(correct: String, correctIndex: Int, language: Language,
                                     seed: UInt64) -> [String] {
        var rng = SeededRandom(seed: seed &+ 0x4348)
        var pool: [String] = []
        let taken = [correct.lowercased()]
        for item in SentenceSelector.bank(language) {
            for word in item.words {
                let text = word.text
                if taken.contains(text.lowercased()) || pool.contains(where: { $0.lowercased() == text.lowercased() }) {
                    continue
                }
                pool.append(text)
            }
        }
        var others = Array(rng.shuffled(pool).prefix(2))
        let fallbacks = language == .fr ? ["le", "la", "un", "une", "et"] : ["the", "a", "and", "is", "it"]
        for filler in fallbacks where others.count < 2 {
            let free = !taken.contains(filler)
                && !others.contains(where: { $0.lowercased() == filler })
            if free { others.append(filler) }
        }
        var out = others
        out.insert(correct, at: min(max(correctIndex, 0), out.count))
        return out
    }
}
