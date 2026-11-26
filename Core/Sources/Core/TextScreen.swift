/// The label and icon of a tap-to-reveal text help control.
public struct TextScreenHelpStep: Equatable, Sendable {
    public let accessibilityLabel: String
    public let iconName: String

    static func steps(language: Language) -> [TextScreenHelpStep] {
        TextQuestionKeys.all.enumerated().map { index, key in
            TextScreenHelpStep(accessibilityLabel: TextTable.string(key, language),
                               iconName: ChromeCatalog.helpSymbolNames[index])
        }
    }
}

/// The text question as presented, without the placeholder item's generic prompt or stimulus.
public struct TextScreen: Equatable, Sendable {
    public let questionId: String
    public let promptText: String
    public let sentences: [[String]]
    public let choices: [String]
    public let correctChoiceIndex: Int
    public let hearLabel: String
    public let choiceLabel: String
    public let helpSteps: [TextScreenHelpStep]
    public let revealedSteps: Set<Int>
    public let markedSentence: Int?
    public let linkedName: String?
    public let evidenceText: String?
    public let evidenceIconName: String?

    public var hearIconName: String { ChromeCatalog.symbolName(for: .ear) }

    init(questionId: String, question: TextQuestion, language: Language, revealedSteps: Set<Int>) {
        self.questionId = questionId
        promptText = question.promptText
        sentences = question.sentences
        choices = question.choices
        correctChoiceIndex = question.correctChoiceIndex
        hearLabel = question.hearLabel
        choiceLabel = TextTable.string("a11y.choice", language)
        helpSteps = TextScreenHelpStep.steps(language: language)
        self.revealedSteps = revealedSteps
        markedSentence = revealedSteps.contains(0) ? question.help(step: 1).markedSentence : nil
        linkedName = revealedSteps.contains(1) ? question.help(step: 2).linkedName : nil
        let evidence = revealedSteps.contains(2) ? question.help(step: 3) : nil
        evidenceText = evidence?.evidenceSentence.flatMap { index in
            question.sentences.indices.contains(index) ? question.sentences[index].joined(separator: " ") : nil
        }
        evidenceIconName = evidence?.linkIcon
    }
}
