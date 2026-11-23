public enum AnswerOutcome: Sendable, Equatable {
    case advanced
    case completed
    case wrong
    case ignored
}

/// One play of a level: five questions, unlimited retries, exactly 3 stars on completion.
public struct Round: Sendable, Equatable {
    public static let starsOnCompletion = 3

    public let levelId: String
    public let seed: UInt64
    public let items: [Item]
    public private(set) var currentIndex: Int = 0
    public private(set) var helperVisible: Bool = false
    public private(set) var wrongAttempts: Int = 0
    /// Wrong choice indices tapped on the current question.
    public private(set) var wrongChoices: Set<Int> = []
    /// Wrong taps on the current question, repeats included; drives how many help steps show.
    public private(set) var wrongTapsOnCurrent: Int = 0
    public private(set) var isComplete: Bool = false

    public init(levelId: String, seed: UInt64) {
        let generate = Curriculum.all.first { $0.levelId == levelId }?.generator
        self.init(levelId: levelId, seed: seed,
                  items: generate?(seed) ?? CountingBondsGenerator.items(seed: seed))
    }

    public init(levelId: String, seed: UInt64, items: [Item]) {
        self.levelId = levelId
        self.seed = seed
        self.items = items
    }

    public var currentItem: Item { items[currentIndex] }

    /// The same round opened at question `index` (clamped to the questions it holds).
    public func starting(at index: Int) -> Round {
        var copy = self
        copy.currentIndex = min(max(0, index), max(0, items.count - 1))
        return copy
    }

    public var starsAwarded: Int { isComplete ? Round.starsOnCompletion : 0 }

    /// The same round with every unanswered question (the current one and later) mapped by `transform`;
    /// answered questions, the position and the wrong-attempt count are kept.
    func replacingUnanswered(_ transform: (Int, Item) -> Item) -> Round {
        guard !isComplete else { return self }
        let mapped = items.enumerated().map { $0.offset < currentIndex ? $0.element : transform($0.offset, $0.element) }
        var out = Round(levelId: levelId, seed: seed, items: mapped)
        out.currentIndex = currentIndex
        out.wrongAttempts = wrongAttempts
        out.isComplete = isComplete
        if mapped[currentIndex] == items[currentIndex] {
            out.helperVisible = helperVisible
            out.wrongChoices = wrongChoices
            out.wrongTapsOnCurrent = wrongTapsOnCurrent
        }
        return out
    }

    /// `itemIndex` is the question the tap was made on; anything but the current question is ignored.
    public mutating func answer(choiceIndex: Int, itemIndex: Int) -> AnswerOutcome {
        guard !isComplete, itemIndex == currentIndex, (0..<3).contains(choiceIndex) else {
            return .ignored
        }
        guard choiceIndex == currentItem.correctIndex || currentItem.isNotice else {
            wrongAttempts += 1
            wrongTapsOnCurrent += 1
            helperVisible = true
            wrongChoices.insert(choiceIndex)
            return .wrong
        }
        helperVisible = false
        wrongChoices = []
        wrongTapsOnCurrent = 0
        if currentIndex == items.count - 1 {
            isComplete = true
            return .completed
        }
        currentIndex += 1
        return .advanced
    }
}
