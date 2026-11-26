import Observation

public struct RoundSummary: Equatable, Sendable {
    public let stars: Int
}

public enum CueTarget: Equatable, Sendable {
    case dots
    case emptySlots
}

public struct WrongCue: Equatable, Sendable {
    public let target: CueTarget
    public let dimmedChoices: Set<Int>
}

@MainActor
@Observable
public final class RoundViewModel {
    public let levelId: String
    public private(set) var summary: RoundSummary?
    private var round: Round
    private let haptics: any HapticsService
    public private(set) var language: Language
    /// Called once when the fifth question is answered correctly.
    var onComplete: (() -> Void)?
    var onAbandon: (() -> Void)?
    private var abandoned = false
    /// Kit state of the current reading item; nil for math and tap-only items. Reset when the item advances.
    var kit: ReadingKitSession?
    /// Answers whose source counts as decoding evidence (a tap or a kit placement).
    public private(set) var decodingEvidenceCount = 0
    /// The questions the round was planned with; they come back when the language returns to French.
    private var frenchItems: [Item] = []

    /// The older level whose old-friend item this round holds; nil when it holds none.
    var reviewedLevelId: String?
    /// Set when the trail has recorded this round, so it is never recorded twice.
    var isCommitted = false

    public init(levelId: String, seed: UInt64, language: Language, haptics: any HapticsService) {
        self.levelId = levelId
        self.language = language
        self.haptics = haptics
        self.round = Round(levelId: levelId, seed: seed)
        frenchItems = round.items
        refreshHelpLadder()
        resetKit()
    }

    public init(round: Round, language: Language, haptics: any HapticsService) {
        self.levelId = round.levelId
        self.language = language
        self.haptics = haptics
        self.round = round
        frenchItems = round.items
        refreshHelpLadder()
        resetKit()
    }

    /// The three help steps of the current question in the current language.
    public private(set) var helpLadder: [HelpStepPresentation] = []

    /// How many ladder steps the view shows: one more after each wrong choice, none before the first.
    public var revealedHelpSteps: Int {
        round.helperVisible ? min(helpLadder.count, max(1, round.wrongTapsOnCurrent)) : 0
    }

    private func refreshHelpLadder() {
        helpLadder = HelpLadder.steps(item: round.currentItem, levelId: levelId, language: language)
    }

    var items: [Item] { round.items }
    var sawWrongAnswer: Bool { round.wrongAttempts > 0 }
    var wrongAttempts: Int { round.wrongAttempts }

    /// "robot.C1", "robot.C2" or "robot.C3" when the current question is a robot level; nil otherwise.
    public var robotKind: String? { round.currentItem.robotId }
    /// The seed that makes the robot grid of the current question.
    public var robotSeed: UInt64 { UInt64(round.currentItem.configuration) }
    public var questionNumber: Int { round.currentIndex + 1 }
    public var questionCount: Int { round.items.count }
    public var promptKey: String { round.currentItem.promptKey }
    public var promptText: String { TextTable.string(promptKey, language) }
    /// What the ear button speaks: the prompt, plus the stimulus in words for the new activities.
    public var speechText: String { round.currentItem.speechLine(language) }

    /// Math M1 presentation after the revealed help steps; nil for every other question.
    public var m1Presentation: M1Presentation? { round.currentItem.m1Presentation(helpStep: revealedHelpSteps) }

    /// Math M2 presentation after the revealed help steps; nil for every other question.
    public var m2Presentation: M2Presentation? { round.currentItem.m2Presentation(helpStep: revealedHelpSteps) }

    /// Math M3 presentation after the revealed help steps; nil for every other question.
    public var m3Presentation: M3Presentation? { round.currentItem.m3Presentation(helpStep: revealedHelpSteps) }

    /// Math M4 presentation after the revealed help steps; nil for every other question.
    public var m4Presentation: M4Presentation? { round.currentItem.m4Presentation(helpStep: revealedHelpSteps) }

    /// The current question's instruction, split into plain text and its highlighted keyword.
    public var promptSegments: [PromptSegment] { round.currentItem.promptSegments(language) }

    /// Reading presentation of the current question; nil for math and notices.
    public var readingPresentation: ReadingItemPresentation? { round.currentItem.readingPresentation(language) }

    /// The sentence question of the current item, built from the item alone so it is ready before the
    /// first frame; nil for every question that is not a sentence.
    public var sentenceQuestion: SentenceQuestion? {
        SentenceQuestions.question(item: round.currentItem, levelId: levelId)
    }

    /// Identity of the current question; independent of language.
    public var identity: ActivityIdentity { round.currentItem.identity }

    /// Switches the display language in place; position and attempts are untouched.
    public func setLanguage(_ newLanguage: Language) {
        switchLanguage(newLanguage)
    }

    /// Sets the display language. In a reading round each unanswered question is replaced by a same-level
    /// question in that language, or by a notice when the language has no reading level.
    public func switchLanguage(_ newLanguage: Language) {
        let changed = newLanguage != language
        language = newLanguage
        if changed, frenchItems.contains(where: { $0.readingId.flatMap(ReadingBank.item(id:)) != nil }) {
            let french = frenchItems
            round = round.replacingUnanswered { index, item in
                ReadingLanguages.hasReadingLevel(newLanguage)
                    ? (item.isNotice ? french[index] : item)
                    : (item.isNotice ? item : Item.notice(replacing: item))
            }
        }
        refreshHelpLadder()
        if kit?.item.id != round.currentItem.readingId { resetKit() }
    }

    private var displayedQuestion: ContentHelpState {
        let state = ContentHelpState(item: round.currentItem)
        return round.helperVisible ? ContentHelpStep.highlight.applying(to: state, language: language) : state
    }

    public var choiceLabels: [String] {
        let words = round.currentItem.changeLetterWords()
        return words.isEmpty ? displayedQuestion.choices.map { String($0) } : words
    }
    /// The question's stimulus: present from the start, never changed by hints or language.
    public var stimulus: QuestionStimulus { displayedQuestion.stimulus }
    /// Next-action hint after a wrong answer, in the current language; nil otherwise.
    public var feedbackText: String? { encouragementKey.map { TextTable.string($0, language) } }
    /// Dot groups of the current question, shown from the moment it appears.
    public var helperDots: [Int]? { round.currentItem.dotGroups }
    public var encouragementKey: String? {
        guard round.helperVisible else { return nil }
        return round.currentItem.hintKey
    }

    /// Non-reading cue after a wrong answer; nil otherwise. Never alters the item or answer.
    public var wrongCue: WrongCue? {
        guard round.helperVisible else { return nil }
        let onSlots = identity == .makeTen || identity == .patterns
        return WrongCue(target: onSlots ? .emptySlots : .dots,
                        dimmedChoices: round.wrongChoices)
    }

    public func select(choiceIndex: Int) {
        select(choiceIndex: choiceIndex, questionNumber: questionNumber)
    }

    /// Answer by choice index, tagged with how it was given.
    public func select(choiceIndex: Int, source: AnswerSource) {
        select(choiceIndex: choiceIndex, questionNumber: questionNumber, source: source)
    }

    /// Answers the current item from the kit: the correct index, or another one for a wrong kit state.
    func answerFromKit(correct: Bool) {
        let right = round.currentItem.correctIndex
        select(choiceIndex: correct ? right : (right + 1) % 3, questionNumber: questionNumber, source: .kit)
    }

    private func resetKit() {
        kit = ReadingKitSession.make(for: round.currentItem)
    }

    /// A robot level question is finished: moves on to the next one.
    public func finishRobotQuestion() { answerFromKit(correct: true) }

    /// Answer by choice index; same meaning as `select(choiceIndex:)`.
    public func submit(_ choice: Int) { select(choiceIndex: choice) }

    /// Back arrow: discards this round with no award or save; later answers are ignored.
    public func abandonRound() {
        guard !abandoned, summary == nil else { return }
        abandoned = true
        onAbandon?()
    }

    /// `questionNumber` is the question the tap was made on; stale taps are ignored.
    public func select(choiceIndex: Int, questionNumber: Int) {
        select(choiceIndex: choiceIndex, questionNumber: questionNumber, source: .tap)
    }

    func select(choiceIndex: Int, questionNumber: Int, source: AnswerSource) {
        guard !abandoned else { return }
        let counts = round.currentItem.countsAsDecodingEvidence && ReadingItem.countsAsDecoding(source: source)
        let outcome = round.answer(choiceIndex: choiceIndex, itemIndex: questionNumber - 1)
        if outcome != .ignored, counts { decodingEvidenceCount += 1 }
        switch outcome {
        case .ignored:
            return
        case .wrong:
            haptics.gentle()
        case .advanced:
            refreshHelpLadder()
            resetKit()
        case .completed:
            haptics.success()
            summary = RoundSummary(stars: round.starsAwarded)
            onComplete?()
        }
    }
}
