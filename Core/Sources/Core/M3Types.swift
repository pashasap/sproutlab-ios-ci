/// The three rule families of the Math M3 level (bridge through ten).
public enum M3Family: Int, Sendable, Equatable, Hashable, CaseIterable {
    case makeTen, removeThroughTen, equivalent
}

/// The easier calculation an equivalent-family question stands for; nil for the other families.
public enum M3Example: Int, Sendable, Equatable, Hashable, CaseIterable {
    case doubles, nearDoubles, crossingTen
}

/// One ten-frame of an M3 question: which of the 10 cells are filled and which are empty.
public struct M3TenFrame: Sendable, Equatable {
    public let filled: [Int]
    public let empty: [Int]

    public init(filled: [Int], empty: [Int]) {
        self.filled = filled
        self.empty = empty
    }
}

/// Everything the view needs to draw an M3 question; help changes only the last three fields.
public struct M3Presentation: Sendable, Equatable {
    public let family: M3Family
    public let example: M3Example?
    /// Exactly two ten-frames, the first and the second group the child counts.
    public let frames: [M3TenFrame]
    /// How many filled cells the child takes away; 0 for the make-ten and equivalent families.
    public let removeAmount: Int
    /// Help 1: the two ten-frames are named and outlined.
    public var areFramesRevealed: Bool = false
    /// Help 2: how many cells are needed (or removed) to land on ten.
    public var separatedToTen: Int?
    /// Help 3: what stays after the first step.
    public var remainderAfterFirstStep: Int?

    public init(family: M3Family, example: M3Example?, counts: [Int], removeAmount: Int) {
        self.family = family
        self.example = example
        self.frames = counts.map { M3Presentation.frame(filled: $0) }
        self.removeAmount = removeAmount
    }

    /// The short instruction-only prompt of this question, with its keyword companion.
    public var promptKey: String {
        family == .removeThroughTen ? "m3.prompt.take" : "m3.prompt.count"
    }

    /// The prompt split into plain text and the highlighted keyword in the activity colour.
    public func keywordSegments(_ language: Language) -> [PromptSegment] {
        ActivityIdentity.bridgeTen.segments(forKey: promptKey, language)
    }

    public var filledCounts: [Int] { frames.map { $0.filled.count } }
    public var shownTotal: Int { filledCounts.reduce(0, +) }
    /// The answer counted from the drawn positions and the amount to remove; nothing else decides it.
    public var visibleAnswer: Int { shownTotal - removeAmount }

    /// Help 2 value, derived from the same visible amounts the child sees.
    public var separationToTen: Int? {
        if family == .removeThroughTen { return shownTotal - 10 }
        guard let first = filledCounts.first, first < 10, shownTotal > 10 else { return nil }
        return 10 - first
    }

    /// Help 3 value: what is left once the first step is worked.
    public var remainder: Int? {
        guard let need = separationToTen else { return nil }
        return family == .removeThroughTen ? removeAmount - need : shownTotal - 10
    }

    static func frame(filled: Int) -> M3TenFrame {
        let count = min(max(filled, 0), QuestionStimulus.tenFrameSize)
        return M3TenFrame(filled: Array(0..<count), empty: Array(count..<QuestionStimulus.tenFrameSize))
    }
}

extension Item {
    /// The M3 presentation after `helpStep` help steps (0 = none); only presentation values change.
    public func m3Presentation(helpStep: Int) -> M3Presentation? {
        guard var shown = m3, helpStep > 0 else { return m3 }
        shown.areFramesRevealed = true
        if helpStep >= 2 { shown.separatedToTen = shown.separationToTen }
        if helpStep >= 3 { shown.remainderAfterFirstStep = shown.remainder }
        return shown
    }
}
