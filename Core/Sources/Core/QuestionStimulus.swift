public enum StimulusShape: Sendable, Equatable {
    case filled
    case emptyOutline
    /// A dot taken away: drawn with a contrasting mark, never a thin line in the dot's colour.
    case crossedOut
}

public enum CrossMark: Sendable, Equatable {
    case contrastingMark
    case sameColourLine
}

public struct TrackCell: Sendable, Equatable {
    public let value: Int
    public let shape: StimulusShape

    public init(value: Int, shape: StimulusShape) {
        self.value = value
        self.shape = shape
    }
}

public enum StimulusDetail: Sendable, Equatable {
    case plain
    case dots(total: Int, crossedOut: Int)
    case groups(first: Int, second: Int)
    case numberTrack(cells: [TrackCell], step: Int)
    case quantities(left: Int, right: Int)

    /// Number of dots the stimulus draws (0 for a number track).
    var shownDots: Int {
        switch self {
        case .plain, .numberTrack: return 0
        case let .dots(total: total, crossedOut: _): return total
        case let .groups(first: first, second: second): return first + second
        case let .quantities(left: left, right: right): return left + right
        }
    }
}

public struct StimulusPosition: Sendable, Equatable {
    public let row: Int
    public let column: Int
    public let shape: StimulusShape

    public init(row: Int, column: Int, shape: StimulusShape) {
        self.row = row
        self.column = column
        self.shape = shape
    }
}

/// What the child looks at for a question; fixed for the life of the question.
public struct QuestionStimulus: Sendable, Equatable {
    public static let tenFrameColumns = 5
    public static let tenFrameSize = 10

    public let positions: [StimulusPosition]
    /// True for the make-ten frame (filled and empty slots), false for counted dots.
    public let isTenFrame: Bool
    public let detail: StimulusDetail
    public let crossMark: CrossMark
    /// Meaning of the visible comparison prompt, not an answer or operand.
    public var comparisonUsesLarger: Bool?

    public init(positions: [StimulusPosition], isTenFrame: Bool = false,
                detail: StimulusDetail = .plain, crossMark: CrossMark = .contrastingMark) {
        self.positions = positions
        self.isTenFrame = isTenFrame
        self.detail = detail
        self.crossMark = crossMark
    }

    /// Counting: one filled position per counted object, five per row.
    public static func counting(_ total: Int) -> QuestionStimulus {
        let count = max(0, total)
        return QuestionStimulus(positions: (0..<count).map {
            StimulusPosition(row: $0 / tenFrameColumns, column: $0 % tenFrameColumns, shape: .filled)
        })
    }

    /// Make-ten: a ten-frame of 2 rows of 5 with `given` filled positions, the rest empty outlines.
    public static func tenFrame(given: Int, fill: TenFrameFill = .rows) -> QuestionStimulus {
        let filled = min(max(0, given), tenFrameSize)
        return QuestionStimulus(positions: (0..<tenFrameSize).map {
            let (row, column) = ($0 / tenFrameColumns, $0 % tenFrameColumns)
            return StimulusPosition(row: row, column: column,
                                    shape: fill.rank(row: row, column: column) < filled ? .filled : .emptyOutline)
        }, isTenFrame: true)
    }
}

extension Item {
    public var stimulus: QuestionStimulus {
        if let m4 { return m4.stimulus }
        if let m2 { return m2.stimulus }
        switch detail {
        case .plain: return kind == .bond ? QuestionStimulus.tenFrame(given: operand, fill: tenFrameFill)
                                          : QuestionStimulus.counting(operand)
        case let .dots(total: total, crossedOut: crossed): return .crossedOutDots(total: total, crossed: crossed)
        case let .groups(first: first, second: second): return .groups(first, second)
        case let .numberTrack(cells: cells, step: step): return .track(cells, step: step)
        case let .quantities(left: left, right: right):
            var stimulus = QuestionStimulus.quantities(left, right)
            stimulus.comparisonUsesLarger = comparisonUsesLarger
            return stimulus
        }
    }
}
