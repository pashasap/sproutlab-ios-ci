/// One rung of the three-step text help ladder. It marks and links, never changes the answer.
public struct TextHelp: Sendable, Equatable {
    public let step: Int
    /// Sentence marked at step 1 and kept at every later step.
    public let markedSentence: Int?
    /// The shared name coloured and linked at step 2.
    public let linkedName: String?
    public let colourToken: String?
    public let linkedChoiceIndex: Int?
    /// Step 3: the marked sentence shown beside the right choice.
    public let evidenceSentence: Int?
    public let evidenceChoiceIndex: Int?
    public let linkIcon: String?
    /// Always nil: the ladder leaves the choice to the child.
    public let selectedChoiceIndex: Int?

    static func blank(_ step: Int) -> TextHelp {
        TextHelp(step: step, markedSentence: nil, linkedName: nil, colourToken: nil, linkedChoiceIndex: nil,
                 evidenceSentence: nil, evidenceChoiceIndex: nil, linkIcon: nil, selectedChoiceIndex: nil)
    }
}

/// Everything the view draws for one text question: all the sentences, one prompt, exactly two choices,
/// the whole-text Tap to Hear control and the three help steps.
public struct TextQuestion: Sendable, Equatable {
    /// The text's sentences, each with its words in reading order.
    public let sentences: [[String]]
    public let promptText: String
    public let choices: [String]
    public let correctChoiceIndex: Int
    public let speechText: String
    public let speechLanguage: Language
    public let hearLabel: String
    /// Exactly three steps; none of them changes the answer.
    public let helpSteps: [HelpStepPresentation]
    /// Parallel to `choices`: nil at the answer, a mistake note at the other choice.
    public let misconceptions: [String?]
    /// 0-based sentence that carries the answer.
    let evidenceSentence: Int

    public var voiceTag: String { speechLanguage == .fr ? "fr-FR" : "en-GB" }

    /// Step 0 is the bare question; steps 1 to 3 add marks and never touch the answer.
    public func help(step: Int) -> TextHelp {
        guard step > 0 else { return .blank(0) }
        let name = linkedName()
        let base = TextHelp(step: step, markedSentence: evidenceSentence,
                            linkedName: step == 2 ? name : nil,
                            colourToken: step == 2 ? "colour.accent" : nil,
                            linkedChoiceIndex: step >= 2 ? correctChoiceIndex : nil,
                            evidenceSentence: step >= 3 ? evidenceSentence : nil,
                            evidenceChoiceIndex: step >= 3 ? correctChoiceIndex : nil,
                            linkIcon: step >= 3 ? "link" : nil,
                            selectedChoiceIndex: nil)
        return base
    }

    /// A name that occurs both in the marked sentence and in the right choice.
    func linkedName() -> String? {
        guard sentences.indices.contains(evidenceSentence),
              choices.indices.contains(correctChoiceIndex) else { return nil }
        let wanted = Set(Self.tokens(of: choices[correctChoiceIndex]))
        return sentences[evidenceSentence].first { wanted.contains($0.lowercased()) }?.lowercased()
    }

    static func tokens(of text: String) -> [String] {
        text.lowercased().split { !$0.isLetter }.map(String.init)
    }
}

/// Builds the text question of a reading item from the item alone, so it is ready before the first frame.
public enum TextQuestions {
    static let helpKeys = ["text.help.evidence", "text.help.link", "text.help.show"]

    public static func question(item: Item) -> TextQuestion? {
        guard let id = item.readingId else { return nil }
        let index = item.configuration % 10
        let flip = min(max(item.correctIndex, 0), 1)
        if let text = FrenchTextBank.item(id: id), text.questions.indices.contains(index) {
            return question(text: text, index: index, flip: flip, language: .fr)
        }
        if let text = EnglishTextBank.item(id: id), text.questions.indices.contains(index) {
            return question(text: text, index: index, flip: flip, language: .en)
        }
        return nil
    }

    static func question(text: TextItem, index: Int, flip: Int, language: Language) -> TextQuestion {
        let bank = text.questions[index]
        let right = bank.answerIndex
        let wrong = 1 - right
        var choices = ["", ""]
        var notes: [String?] = [nil, nil]
        choices[flip] = bank.choices[right]
        choices[1 - flip] = bank.choices[wrong]
        notes[flip] = nil
        notes[1 - flip] = bank.misconceptions[wrong]
        return TextQuestion(
            sentences: text.sentences.map { $0.words.map(\.text) },
            promptText: bank.prompt,
            choices: choices,
            correctChoiceIndex: flip,
            speechText: text.sentences.map(\.text).joined(separator: " "),
            speechLanguage: language,
            hearLabel: TextTable.string("text.hear.label", language),
            helpSteps: helpSteps(language),
            misconceptions: notes,
            evidenceSentence: bank.evidenceSentence)
    }

    static func helpSteps(_ language: Language) -> [HelpStepPresentation] {
        HelpLadder.kinds.indices.map { index in
            HelpStepPresentation(kind: HelpLadder.kinds[index],
                                 text: TextTable.string(helpKeys[index], language),
                                 symbolNames: [ChromeCatalog.helpSymbolNames[index]],
                                 colourTokens: ["colour.accent"])
        }
    }
}

/// Picks three distinct texts of the French bank for a round, fixed for a seed.
public enum TextSelector {
    public static func round(seed: UInt64) -> [TextItem] {
        indices(seed: seed).map { FrenchTextBank.items[$0] }
    }

    static func indices(seed: UInt64) -> [Int] {
        shuffledIndices(in: FrenchTextBank.items, seed: seed &+ 0x5438)
    }

    static func shuffledIndices(in bank: [TextItem], seed: UInt64) -> [Int] {
        var rng = SeededRandom(seed: seed)
        let shuffled = rng.shuffled(Array(bank.indices))
        return Array(shuffled.prefix(3))
    }
}

/// One child's attempt at one text question: the ladder, whole-text speech on tap and the answer evidence.
public final class TextSession {
    public let question: TextQuestion
    private let speech: any SpeechService
    private var stepIndex = 0
    /// True once the child heard the whole text on tap.
    private var listened = false

    public init(question: TextQuestion, speech: any SpeechService) {
        self.question = question
        self.speech = speech
    }

    /// The next help step, or nil once the ladder is used up. It never changes the answer or the stars.
    public func help() -> TextHelp? {
        guard stepIndex < question.helpSteps.count else { return nil }
        stepIndex += 1
        return question.help(step: stepIndex)
    }

    /// Tap to Hear: one whole-text call per tap, never a call on its own.
    public func hearText() throws {
        listened = true
        _ = try speech.speak(voiceTag: question.voiceTag, text: question.speechText)
    }

    /// Scores one choice; stars stay three whatever help or listening came before.
    public func submit(choiceIndex: Int) -> SentenceAnswer {
        let isCorrect = choiceIndex == question.correctChoiceIndex
        let note = question.misconceptions.indices.contains(choiceIndex) ? question.misconceptions[choiceIndex] : nil
        return SentenceAnswer(isCorrect: isCorrect, stars: Round.starsOnCompletion,
                              countsAsIndependentDecoding: !listened,
                              misconception: isCorrect ? nil : note)
    }
}
