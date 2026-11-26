/// The three question families of the Math M4 level (build numbers from tens and ones).
public enum M4Family: Int, Sendable, Equatable, Hashable, CaseIterable {
    case bundleTen, buildNumeral, matchModel
}

/// The two place-value buttons of a tens-and-ones question.
public enum M4ButtonKind: Int, Sendable, Equatable, Hashable, CaseIterable {
    case tens, ones

    var textKey: String {
        switch self {
        case .tens: return "m4.button.tens"
        case .ones: return "m4.button.ones"
        }
    }
}

/// One place-value button: at least 56 by 56 points and with a localised label.
public struct M4Button: Sendable, Equatable {
    public let kind: M4ButtonKind
    public let width: Double
    public let height: Double

    public init(kind: M4ButtonKind, width: Double, height: Double) {
        self.kind = kind
        self.width = width
        self.height = height
    }

    public func accessibilityLabel(_ language: Language) -> String {
        TextTable.string(kind.textKey, language)
    }
}

/// Everything the view needs to draw a tens-and-ones question; help only opens the last three fields.
public struct M4Presentation: Sendable, Equatable {
    public let family: M4Family
    /// Bundles of ten the child sees drawn.
    public let bundleCount: Int
    /// Loose units the child sees drawn; always 0 to 9.
    public let looseCount: Int
    /// The numeral the visible model stands for: ten per bundle plus the loose units.
    public var targetNumeral: Int { 10 * bundleCount + looseCount }
    public let buttons: [M4Button]
    /// Help 1: the tens and the ones trays are opened and named.
    public var areTraysOpen: Bool = false
    /// Help 2: the value of each bundle, ten apiece.
    public var bundleValues: [Int]?
    /// Help 3: the tens digit's own contribution to the numeral.
    public var digitContribution: Int?

    public init(family: M4Family, bundleCount: Int, looseCount: Int, buttons: [M4Button]) {
        self.family = family
        self.bundleCount = bundleCount
        self.looseCount = looseCount
        self.buttons = buttons
    }

    /// Both place-value buttons, each at the minimum touch size.
    public static let standardButtons: [M4Button] = M4ButtonKind.allCases.map {
        M4Button(kind: $0, width: Touch.minimumPoints, height: Touch.minimumPoints)
    }

    /// The short instruction-only prompt of this question, with its keyword companion.
    public var promptKey: String {
        switch family {
        case .bundleTen: return "m4.prompt.bundle"
        case .buildNumeral: return "m4.prompt.build"
        case .matchModel: return "m4.prompt.match"
        }
    }

    /// The prompt split into plain text and the highlighted keyword in the activity colour.
    public func keywordSegments(_ language: Language) -> [PromptSegment] {
        ActivityIdentity.tensOnes.segments(forKey: promptKey, language)
    }

    /// The drawn model: ten marks per bundle, then one mark per loose unit.
    /// Counted back, the drawn marks give `targetNumeral`, so help cannot change the answer.
    public var stimulus: QuestionStimulus {
        var positions: [StimulusPosition] = []
        for bundle in 0..<max(0, bundleCount) {
            let base = bundle * 2
            for mark in 0..<QuestionStimulus.tenFrameSize {
                positions.append(StimulusPosition(row: base + mark / QuestionStimulus.tenFrameColumns,
                                                  column: mark % QuestionStimulus.tenFrameColumns,
                                                  shape: .filled))
            }
        }
        let base = max(0, bundleCount) * 2
        for mark in 0..<max(0, looseCount) {
            positions.append(StimulusPosition(row: base + mark / QuestionStimulus.tenFrameColumns,
                                              column: mark % QuestionStimulus.tenFrameColumns,
                                              shape: .filled))
        }
        return QuestionStimulus(positions: positions)
    }
}

extension Item {
    /// The M4 presentation after `helpStep` help steps (0 = none); only presentation values change.
    public func m4Presentation(helpStep: Int) -> M4Presentation? {
        guard var shown = m4, helpStep > 0 else { return m4 }
        shown.areTraysOpen = true
        if helpStep >= 2 { shown.bundleValues = Array(repeating: 10, count: shown.bundleCount) }
        if helpStep >= 3 { shown.digitContribution = 10 * shown.bundleCount }
        return shown
    }
}
