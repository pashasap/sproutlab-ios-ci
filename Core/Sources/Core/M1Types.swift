/// The three question kinds of the Math M1 level (count without double-counting).
public enum M1QuestionKind: Int, Sendable, Equatable, Hashable, CaseIterable {
    case tapCount, fillTray, matchGroups
}

public enum M1Layout: Int, Sendable, Equatable, Hashable {
    case clustered, scattered

    var other: M1Layout { self == .clustered ? .scattered : .clustered }
}

/// One drawn object: position in the unit square and a relative size.
public struct M1Object: Sendable, Equatable {
    public let x: Double
    public let y: Double
    public let size: Double
}

public struct M1Collection: Sendable, Equatable {
    public let layout: M1Layout
    public let objects: [M1Object]
}

public struct M1TraySlot: Sendable, Equatable {
    public let isFilled: Bool
}

/// Everything the view needs to draw an M1 question; help changes only the last three fields.
public struct M1Presentation: Sendable, Equatable {
    public let kind: M1QuestionKind
    /// tapCount: the shown collection; fillTray: the supply; matchGroups: the target.
    public var groups: [M1Collection]
    /// The three numerals offered with the question: distinct, and one of them is the object count.
    public var choices: [Int] = []
    /// matchGroups only: one collection per numeral choice, parallel to the item's choices.
    public var choiceGroups: [M1Collection] = []
    /// fillTray only: the tray; the answer is the number of empty slots.
    public var traySlots: [M1TraySlot] = []
    /// Parallel to the objects of the first group; all false before help.
    public var countedMarks: [Bool]
    public var isRowArranged: Bool = false
    public var demonstratedCount: Int?

    init(kind: M1QuestionKind, groups: [M1Collection]) {
        self.kind = kind
        self.groups = groups
        self.countedMarks = Array(repeating: false, count: groups.first?.objects.count ?? 0)
    }
}

extension Item {
    /// The M1 presentation after `helpStep` help steps (0 = none); only presentation values change.
    public func m1Presentation(helpStep: Int) -> M1Presentation? {
        guard var shown = m1, helpStep > 0, let first = shown.groups.first else { return m1 }
        let count = first.objects.count
        shown.countedMarks = Array(repeating: true, count: count)
        if helpStep >= 2 {
            let row = first.objects.enumerated().map {
                M1Object(x: (Double($0.offset) + 0.5) / Double(max(count, 1)), y: 0.5, size: $0.element.size)
            }
            shown.groups[0] = M1Collection(layout: first.layout, objects: row)
            shown.isRowArranged = true
        }
        if helpStep >= 3 { shown.demonstratedCount = max(count - 1, 0) }
        return shown
    }
}
