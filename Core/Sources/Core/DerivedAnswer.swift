public struct StimulusMeaning: Sendable, Equatable {
    public let filled: Int
    public let empty: Int
    public let crossedOut: Int

    public init(_ stimulus: QuestionStimulus) {
        filled = stimulus.positions.filter { $0.shape == .filled }.count
        empty = stimulus.positions.filter { $0.shape == .emptyOutline }.count
        crossedOut = stimulus.positions.filter { $0.shape == .crossedOut }.count
    }
}

/// Independent oracle: reads only what is drawn, never generator arithmetic or an Item answer.
public enum DerivedAnswer {
    public static func from(_ stimulus: QuestionStimulus) -> Int? {
        let counts = StimulusMeaning(stimulus)
        switch stimulus.detail {
        case .plain: return stimulus.isTenFrame ? counts.empty : counts.filled
        case .groups, .dots: return counts.filled
        case .quantities:
            guard let larger = stimulus.comparisonUsesLarger else { return nil }
            let left = stimulus.positions.filter {
                $0.column < QuestionStimulus.tenFrameColumns && $0.shape == .filled
            }.count
            let right = counts.filled - left
            return larger ? max(left, right) : min(left, right)
        case let .numberTrack(cells, _): return trackAnswer(cells, positions: stimulus.positions)
        }
    }

    private static func trackAnswer(_ cells: [TrackCell], positions: [StimulusPosition]) -> Int? {
        guard cells.count == positions.count,
              zip(cells, positions).allSatisfy({ $0.shape == $1.shape }) else { return nil }
        let visible = cells.indices.filter { positions[$0].shape == .filled }
        let missing = cells.indices.filter { positions[$0].shape == .emptyOutline }
        guard visible.count >= 2, missing.count == 1 else { return nil }
        let first = visible[0]
        let second = visible[1]
        let difference = cells[second].value - cells[first].value
        let distance = second - first
        guard difference % distance == 0 else { return nil }
        let step = difference / distance
        guard visible.allSatisfy({ cells[$0].value == cells[first].value + ($0 - first) * step }) else {
            return nil
        }
        return cells[first].value + (missing[0] - first) * step
    }
}
