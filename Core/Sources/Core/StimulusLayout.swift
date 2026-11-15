/// One group of dots in a two-group stimulus; its count is readable on its own.
public struct StimulusGroup: Sendable, Equatable {
    /// Gap between the two groups, in dot pitches (at least one).
    public static let gapInPitches: Double = 1

    public let count: Int

    public init(count: Int) {
        self.count = count
    }
}

/// Where one drawn position (an index into `StimulusPresentation.positions`) sits in the laid-out grid.
public struct StimulusPlacement: Sendable, Equatable {
    public let index: Int
    public let row: Int
    public let column: Int
}

/// A width-fitting layout of a stimulus; the view only draws it.
public struct StimulusLayout: Sendable, Equatable {
    public let dotSize: Double
    public let spacing: Double
    public let availableWidth: Double
    public let placements: [StimulusPlacement]

    public init(dotSize: Double, spacing: Double, availableWidth: Double, placements: [StimulusPlacement]) {
        self.dotSize = dotSize
        self.spacing = spacing
        self.availableWidth = availableWidth
        self.placements = placements
    }

    public var pitch: Double { dotSize + spacing }
    public var columns: Int { (placements.map(\.column).max() ?? -1) + 1 }
    public var rows: Int { (placements.map(\.row).max() ?? -1) + 1 }
    public var totalWidth: Double { columns == 0 ? 0 : Double(columns) * pitch - spacing }
    public var totalHeight: Double { rows == 0 ? 0 : Double(rows) * pitch - spacing }
    public var isClipped: Bool { totalWidth > availableWidth }
}

extension LayoutPolicy {
    public static let minimumDotSize: Double = 28
    public static let trackCellSize: Double = 48
    public static let stimulusSpacing: Double = 8

    /// Lays a stimulus out inside `availableWidth` (already without safe-area margins): the dot size stays put and
    /// groups wrap to more rows instead of shrinking or clipping.
    public static func stimulusLayout(_ presentation: StimulusPresentation, availableWidth: Double) -> StimulusLayout {
        let size = presentation.trackValues.isEmpty ? minimumDotSize : trackCellSize
        let pitch = size + stimulusSpacing
        let fitting = max(1, Int(((availableWidth + stimulusSpacing) / pitch).rounded(.down)))
        let placements: [StimulusPlacement]
        if presentation.groups.count == 2 {
            let gapColumns = Int(presentation.groupGap.rounded(.up))
            let perGroup = max(1, min(QuestionStimulus.tenFrameColumns, (fitting - gapColumns) / 2))
            placements = groupPlacements(presentation.groups.map(\.count), perGroup: perGroup, gapColumns: gapColumns)
        } else {
            placements = wrappedPlacements(presentation.positions, perRow: fitting)
        }
        return StimulusLayout(dotSize: size, spacing: stimulusSpacing, availableWidth: availableWidth,
                              placements: placements)
    }

    private static func groupPlacements(_ counts: [Int], perGroup: Int, gapColumns: Int) -> [StimulusPlacement] {
        var result: [StimulusPlacement] = []
        var index = 0
        for (groupNumber, count) in counts.enumerated() {
            let offset = groupNumber * (perGroup + gapColumns)
            for slot in 0..<max(0, count) {
                result.append(StimulusPlacement(index: index, row: slot / perGroup, column: offset + slot % perGroup))
                index += 1
            }
        }
        return result
    }

    private static func wrappedPlacements(_ positions: [StimulusPosition], perRow: Int) -> [StimulusPlacement] {
        let columns = (positions.map(\.column).max() ?? -1) + 1
        let bandHeight = (positions.map(\.row).max() ?? -1) + 1
        let perBand = min(max(columns, 1), perRow)
        return positions.enumerated().map { offset, position in
            StimulusPlacement(index: offset, row: position.row + (position.column / perBand) * bandHeight,
                              column: position.column % perBand)
        }
    }
}

/// Lint: a two-group stimulus must keep two groups of the operand counts with an empty column between them.
public enum StimulusGroupLint {
    public static func violations(in stimuli: [QuestionStimulus]) -> [String] {
        stimuli.enumerated().compactMap { offset, stimulus in
            let counts: (Int, Int)
            switch stimulus.detail {
            case let .groups(first: first, second: second), let .quantities(left: first, right: second):
                counts = (first, second)
            default:
                return nil
            }
            guard stimulus.positions.count == counts.0 + counts.1 else {
                return "stimulus \(offset): \(stimulus.positions.count) dots for groups \(counts.0) and \(counts.1)"
            }
            guard counts.0 > 0, counts.1 > 0 else { return nil }
            let first = stimulus.positions.prefix(counts.0).map(\.column)
            let second = stimulus.positions.suffix(counts.1).map(\.column)
            guard let firstEnd = first.max(), let secondStart = second.min(), secondStart - firstEnd >= 2 else {
                return "stimulus \(offset): groups \(counts.0) and \(counts.1) merged or without a gap"
            }
            return nil
        }
    }
}
