/// The three shapes a French sentence question can take.
public enum SentenceKind: String, CaseIterable, Sendable, Equatable {
    case complete, scene, order
}

/// One written word of a sentence: its spelling, its graphemes, and whether it is a sight word.
public struct SentenceWord: Sendable, Equatable {
    public let text: String
    /// Grapheme tokens; a silent letter is written with a leading `~` (for example `~s`).
    public let graphemes: [String]
    /// Sight words are read whole and carry no graphemes.
    public let isSight: Bool

    public init(text: String, graphemes: [String], isSight: Bool) {
        self.text = text
        self.graphemes = graphemes
        self.isSight = isSight
    }
}

/// One sentence of the French r6 bank.
public struct SentenceItem: Sendable, Equatable, Identifiable {
    public let id: String
    public let kind: SentenceKind
    public var words: [SentenceWord]
    /// The visible sentence the child reads; words joined by one space.
    public var sentence: String
    /// Position role inside a round; nil until the item is placed.
    public var role: ItemRole?

    public init(id: String, kind: SentenceKind, words: [SentenceWord], role: ItemRole? = nil) {
        self.id = id
        self.kind = kind
        self.words = words
        self.sentence = words.map(\.text).joined(separator: " ")
        self.role = role
    }
}

/// One scene drawing: the objects both scenes of an item share, and the detail that differs.
public struct SceneRecipe: Sendable, Equatable {
    public let objects: [String]
    public let detail: String
    /// Never set on a decode-scored item: a caption would name the answer.
    public let caption: String?
    public let label: String?

    public init(objects: [String], detail: String, caption: String? = nil, label: String? = nil) {
        self.objects = objects
        self.detail = detail
        self.caption = caption
        self.label = label
    }
}

/// One offered word of a complete-the-sentence question.
public struct SentenceChoice: Sendable, Equatable {
    public let text: String
    /// The mistake this distractor stands for; nil only on the right choice.
    public let misconception: String?

    public init(text: String, misconception: String?) {
        self.text = text
        self.misconception = misconception
    }
}

/// Everything the view draws for one sentence item.
public struct SentencePresentation: Sendable, Equatable {
    /// The token drawn in place of the missing word.
    public static let blankToken = "▁▁▁▁"

    public let kind: SentenceKind
    public let visibleWords: [String]
    public internal(set) var blankIndex: Int?
    public internal(set) var choices: [SentenceChoice] = []
    public internal(set) var scenes: [SceneRecipe] = []
    public internal(set) var correctSceneIndex: Int?
    public internal(set) var tiles: [String] = []

    public init(kind: SentenceKind, visibleWords: [String]) {
        self.kind = kind
        self.visibleWords = visibleWords
    }

    /// The ordering kit of an order item: tap a tile to place it.
    public func ordering() throws -> KitOrdering {
        try KitOrdering(tokens: tiles)
    }
}

/// One rung of the three-step sentence help ladder.
public enum SentenceHelpStep: Sendable, Equatable {
    /// Step 1: the words with their boundaries shown.
    case boundaries([String])
    /// Step 2: the subject phrase, then the rest, derived by rule.
    case phraseGroups(subject: [String], rest: [String])
    /// Step 3: one phrase modelled, spoken only on tap and shown in place.
    case modelPhrase(String)
}

/// What one answer is worth.
public struct SentenceAnswer: Sendable, Equatable {
    public let isCorrect: Bool
    public let stars: Int
    /// False once the child heard the sentence or the modelled phrase: that answer is not decoding evidence.
    public let countsAsIndependentDecoding: Bool
    public let misconception: String?
}
