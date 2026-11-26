/// The three question kinds of the Math M2 level (compose and decompose ten).
public enum M2QuestionKind: Int, Sendable, Equatable, Hashable, CaseIterable {
    case fillTenFrame, pickBaskets, missingPart
}

/// The ten-frame of an M2 question: which of the 10 cells are filled and which are empty.
public struct M2TenFrame: Sendable, Equatable {
    public let filled: [Int]
    public let empty: [Int]

    public init(filled: [Int], empty: [Int]) {
        self.filled = filled
        self.empty = empty
    }
}

public struct M2Basket: Sendable, Equatable {
    public let count: Int

    public init(count: Int) {
        self.count = count
    }
}

/// Which part of a two-part equation carries the missing value.
public enum M2Slot: Int, Sendable, Equatable, Hashable, CaseIterable {
    case first, second, total
}

/// A two-part equation; exactly one part is nil, named by `missing`.
public struct M2Equation: Sendable, Equatable {
    public let first: Int?
    public let second: Int?
    public let total: Int?
    public let missing: M2Slot

    public init(first: Int?, second: Int?, total: Int?, missing: M2Slot) {
        self.first = first
        self.second = second
        self.total = total
        self.missing = missing
    }
}

/// Everything the view needs to draw an M2 question; help changes only the last three fields.
public struct M2Presentation: Sendable, Equatable {
    public let kind: M2QuestionKind
    /// fillTenFrame: the partly filled frame; missingPart: the known part filled, the missing one empty.
    public let frame: M2TenFrame
    /// pickBaskets: the two baskets the child looks at; empty for the other kinds.
    public var baskets: [M2Basket]
    public let targetTotal: Int
    public let equation: M2Equation
    /// pickBaskets only: one basket pair per numeral choice, parallel to the item's choices.
    public var choiceBaskets: [[M2Basket]]
    /// Help 1: the whole (the target total) is named.
    public var isWholeRevealed: Bool
    /// Help 2: the occupied and the empty spaces are shown.
    public var areSpacesShown: Bool
    /// Help 3: 0 or 1, the part moved into a worked partition.
    public var movedPartIndex: Int?

    public init(kind: M2QuestionKind, frame: M2TenFrame, targetTotal: Int, equation: M2Equation) {
        self.kind = kind
        self.frame = frame
        self.baskets = []
        self.targetTotal = targetTotal
        self.equation = equation
        self.choiceBaskets = []
        self.isWholeRevealed = false
        self.areSpacesShown = false
        self.movedPartIndex = nil
    }
}

extension M2Presentation {
    /// What the child looks at, derived from the presentation values only.
    public var stimulus: QuestionStimulus {
        switch kind {
        case .fillTenFrame, .missingPart:
            return .cells(filled: frame.filled, empty: frame.empty)
        case .pickBaskets:
            return QuestionStimulus(positions: (0..<max(0, targetTotal)).map {
                StimulusPosition(row: $0 / QuestionStimulus.tenFrameColumns,
                                 column: $0 % QuestionStimulus.tenFrameColumns, shape: .filled)
            })
        }
    }
}

extension QuestionStimulus {
    /// A ten-frame drawn from the filled and the empty cell indices of an M2 frame.
    static func cells(filled: [Int], empty: [Int]) -> QuestionStimulus {
        let drawn = filled.map { ($0, StimulusShape.filled) } + empty.map { ($0, StimulusShape.emptyOutline) }
        let positions = drawn.sorted { $0.0 < $1.0 }.map {
            StimulusPosition(row: $0.0 / QuestionStimulus.tenFrameColumns,
                             column: $0.0 % QuestionStimulus.tenFrameColumns, shape: $0.1)
        }
        return QuestionStimulus(positions: positions, isTenFrame: true)
    }
}

extension Item {
    /// The M2 presentation after `helpStep` help steps (0 = none); only presentation values change.
    public func m2Presentation(helpStep: Int) -> M2Presentation? {
        guard var shown = m2, helpStep > 0 else { return m2 }
        shown.isWholeRevealed = true
        if helpStep >= 2 { shown.areSpacesShown = true }
        if helpStep >= 3 { shown.movedPartIndex = 0 }
        return shown
    }
}
