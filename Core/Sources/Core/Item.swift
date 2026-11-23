public enum ItemKind: String, Sendable, Equatable, Codable {
    case counting
    case bond
    case addition
    case subtraction
    case pattern
    case comparison
}

/// What an item is for within a five-position round.
public enum ItemRole: String, Sendable, Equatable, Codable {
    case familiar
    case current
    case unfamiliarTransfer
}

/// The order in which a make-ten frame's filled places are laid out; the answer never depends on it.
public enum TenFrameFill: Int, Sendable, Equatable, Codable, CaseIterable {
    case rows
    case columns
    case mirroredRows

    /// Rank of the place at `row`, `column` in the fill order.
    func rank(row: Int, column: Int) -> Int {
        let width = QuestionStimulus.tenFrameColumns
        switch self {
        case .rows: return row * width + column
        case .columns: return column * 2 + row
        case .mirroredRows: return row * width + (width - 1 - column)
        }
    }
}

public struct Item: Sendable, Equatable {
    public let kind: ItemKind
    /// Counted number (counting), `a` of `a + ? = 10` (bond), or the number of dots shown for the new kinds.
    public let operand: Int
    public let answer: Int
    public let choices: [Int]
    public let correctIndex: Int
    /// Dots shown for the question: the counted number, or the given amount `a` for a bond.
    public let dotGroups: [Int]
    /// Text-table key of this question type's icon.
    public internal(set) var iconKey: String
    /// Name of this question type's colour (the app maps it to a palette colour).
    public let colourName: String
    /// The variant of the question (what makes it familiar or new to the child); defaults to the operand.
    public var configuration: Int
    /// The question's comparison intent, independent of the generated answer.
    public var comparisonUsesLarger: Bool = false
    /// What the child looks at; `.plain` for counting and make-ten.
    public let detail: StimulusDetail
    /// Parallel to `choices`: the mistake each wrong option stands for; nil at the correct index.
    public private(set) var misconceptions: [Misconception?]
    /// True only for the fifth item of a round: a question of a new kind for the child.
    public private(set) var isUnfamiliarTransfer: Bool = false
    /// Position role in the round: familiar, current, current, current, unfamiliar transfer.
    public private(set) var role: ItemRole = .current
    /// Layout of the filled places of a make-ten frame.
    public private(set) var tenFrameFill: TenFrameFill = .rows
    /// The reading bank item this item stands for; nil for math items.
    public var readingId: String?
    /// The robot level kind this item stands for ("robot.C1"); nil for every other item.
    public var robotId: String?
    /// True for the icon-led notice that stands in for a reading question the language has no level for.
    public internal(set) var isNotice: Bool = false
    /// Text key of the notice; nil for every other item.
    public internal(set) var noticeTextKey: String?
    /// A notice is never decoding evidence; every reading question is.
    public var countsAsDecodingEvidence: Bool { !isNotice }

    /// This item with the role of the 1-based `position` in a round of `count` items.
    func placed(at position: Int, of count: Int) -> Item {
        var out = self
        out.isUnfamiliarTransfer = position == count
        out.role = position == 1 ? .familiar : (position == count ? .unfamiliarTransfer : .current)
        return out
    }

    /// A make-ten item with another frame layout; the configuration tells the layouts apart.
    func filled(_ fill: TenFrameFill) -> Item {
        var out = self
        out.tenFrameFill = fill
        out.configuration = operand + 100 * fill.rawValue
        return out
    }

    public init(kind: ItemKind, operand: Int, choices: [Int], correctIndex: Int) {
        self.kind = kind
        self.operand = operand
        self.configuration = operand
        self.choices = choices
        self.correctIndex = correctIndex
        self.dotGroups = CountingBondsGenerator.groups(total: operand)
        self.answer = choices[correctIndex]
        self.iconKey = kind == .counting ? "icon.counting" : "icon.bond"
        self.colourName = kind == .counting ? "colour.counting" : "colour.bond"
        self.detail = .plain
        self.misconceptions = choices.map { _ in nil }
    }

    /// A counting or make-ten item whose wrong options carry their misconceptions.
    init(kind: ItemKind, operand: Int, options: ItemOptions) {
        self.init(kind: kind, operand: operand, choices: options.choices, correctIndex: options.correctIndex)
        self.misconceptions = options.misconceptions
    }

    /// An item of the add/subtract and patterns levels.
    init(kind: ItemKind, detail: StimulusDetail, options: ItemOptions, configuration: Int) {
        let shown = detail.shownDots
        self.kind = kind
        self.operand = shown
        self.configuration = configuration
        self.choices = options.choices
        self.correctIndex = options.correctIndex
        self.dotGroups = CountingBondsGenerator.groups(total: shown)
        self.answer = options.choices[options.correctIndex]
        self.iconKey = kind == .counting ? "icon.counting" : "icon.math"
        self.colourName = kind == .counting ? "colour.counting" : "colour.math"
        self.detail = detail
        self.misconceptions = options.misconceptions
    }

    /// The same question with its options in a new order (`order[i]` is the old index shown at `i`).
    func reordered(_ order: [Int]) -> Item {
        let options = ItemOptions(choices: order.map { choices[$0] },
                                  correctIndex: order.firstIndex(of: correctIndex) ?? 0,
                                  misconceptions: order.map { misconceptions[$0] })
        var out = detail == .plain
            ? Item(kind: kind, operand: operand, options: options)
            : Item(kind: kind, detail: detail, options: options, configuration: configuration)
        out.configuration = configuration
        out.comparisonUsesLarger = comparisonUsesLarger
        out.isUnfamiliarTransfer = isUnfamiliarTransfer
        out.role = role
        out.tenFrameFill = tenFrameFill
        out.readingId = readingId
        out.robotId = robotId
        out.isNotice = isNotice
        out.noticeTextKey = noticeTextKey
        out.iconKey = iconKey
        return out
    }

    /// Text key of the short child-path prompt (1 to 3 words).
    public var promptKey: String {
        if let noticeTextKey { return noticeTextKey }
        if readingId != nil, let key = identity.promptKey { return key }
        switch kind {
        case .counting: return "round.prompt.count"
        case .bond: return "round.prompt.bond"
        case .addition: return "round.prompt.add"
        case .subtraction: return "round.prompt.subtract"
        case .pattern: return "round.prompt.pattern"
        case .comparison: return asksLarger ? "round.prompt.larger" : "round.prompt.smaller"
        }
    }

    /// True when a comparison asks for the larger quantity.
    var asksLarger: Bool {
        kind == .comparison && comparisonUsesLarger
    }
}
