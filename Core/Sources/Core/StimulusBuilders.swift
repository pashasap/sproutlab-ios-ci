extension QuestionStimulus {
    private static func dotPositions(_ count: Int, columnOffset: Int = 0, shapes: (Int) -> StimulusShape = { _ in .filled })
        -> [StimulusPosition] {
        (0..<max(0, count)).map {
            StimulusPosition(row: $0 / tenFrameColumns, column: columnOffset + $0 % tenFrameColumns, shape: shapes($0))
        }
    }

    /// `total` dots in rows of five; the last `crossed` of them carry the contrasting cross mark.
    static func crossedOutDots(total: Int, crossed: Int) -> QuestionStimulus {
        let kept = total - crossed
        return QuestionStimulus(positions: dotPositions(total) { $0 < kept ? .filled : .crossedOut },
                                detail: .dots(total: total, crossedOut: crossed))
    }

    /// Two groups of filled dots side by side.
    static func groups(_ first: Int, _ second: Int) -> QuestionStimulus {
        QuestionStimulus(positions: dotPositions(first) + dotPositions(second, columnOffset: tenFrameColumns + 1),
                         detail: .groups(first: first, second: second))
    }

    /// Two quantities of dots side by side.
    static func quantities(_ left: Int, _ right: Int) -> QuestionStimulus {
        QuestionStimulus(positions: dotPositions(left) + dotPositions(right, columnOffset: tenFrameColumns + 1),
                         detail: .quantities(left: left, right: right))
    }

    /// A number track in one row; the missing place is an outlined empty slot.
    static func track(_ cells: [TrackCell], step: Int) -> QuestionStimulus {
        QuestionStimulus(positions: cells.enumerated().map {
            StimulusPosition(row: 0, column: $0.offset, shape: $0.element.shape)
        }, detail: .numberTrack(cells: cells, step: step))
    }

    /// Spoken description of the stimulus, from the same positions the view draws.
    public func accessibilityValue(_ language: Language) -> String {
        let filled = positions.filter { $0.shape == .filled }.count
        let crossed = positions.filter { $0.shape == .crossedOut }.count
        let empty = positions.filter { $0.shape == .emptyOutline }.count
        let fr = language == .fr
        switch detail {
        case let .quantities(left: left, right: right):
            let join = TextTable.string("equiv.and", language)
            return Self.dotCount(left, fr) + join + Self.dotCount(right, fr)
        case let .groups(first: first, second: second):
            let join = TextTable.string("equiv.and", language)
            return Self.dotCount(first, fr) + join + Self.dotCount(second, fr)
        case .dots:
            return fr ? "\(filled) \(Self.plural(filled, "plein", "pleins")), \(crossed) \(Self.plural(crossed, "barré", "barrés"))"
                      : "\(filled) filled, \(crossed) crossed out"
        case .numberTrack:
            return fr ? "\(filled) \(Self.plural(filled, "plein", "pleins")), \(empty) \(Self.plural(empty, "vide", "vides"))"
                      : "\(filled) filled, \(empty) empty"
        case .plain:
            return plainValue(filled: filled, empty: empty, fr: fr)
        }
    }

    private func plainValue(filled: Int, empty: Int, fr: Bool) -> String {
        if isTenFrame {
            return fr ? "\(filled) pleins, \(empty) vides" : "\(filled) filled, \(empty) empty"
        }
        if fr { return filled == 1 ? "1 point" : "\(filled) points" }
        return filled == 1 ? "1 dot" : "\(filled) dots"
    }

    private static func plural(_ count: Int, _ one: String, _ many: String) -> String {
        count > 1 ? many : one
    }

    private static func dotCount(_ count: Int, _ fr: Bool) -> String {
        fr ? "\(count) \(plural(count, "point", "points"))" : "\(count) \(plural(count, "dot", "dots"))"
    }
}
