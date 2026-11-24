/// What a stimulus view draws and speaks: positions, colour tokens, identity and both-language texts.
public struct StimulusPresentation: Sendable, Equatable {
    public let identifier: String
    public let positions: [StimulusPosition]
    /// Track numbers aligned with `positions`; nil for an outlined empty slot (and for every non-track stimulus).
    public let trackValues: [Int?]
    public let isTenFrame: Bool
    public let contrastMarkKind: CrossMark
    public let dotColourToken: String
    public let markColourToken: String
    public let haloColourToken: String
    public let accessibilityValueEN: String
    public let accessibilityValueFR: String
    public let textEquivalentEN: String
    public let textEquivalentFR: String
    /// SF Symbol names the stimulus draws; always from the Core catalog (none today).
    public let _symbolNames: [String]
    /// The written comparison sign (">" or "<"), a text glyph rather than an SF Symbol.
    public let comparisonSign: [String]
    /// Everything the stimulus shows as a symbol: catalog symbols then the written sign.
    public var symbolNames: [String] { _symbolNames + comparisonSign }
    public let colourTokens: [String]
    /// Written formula of an addition or subtraction round; nil otherwise.
    public let formula: String?
    /// The two groups of an addition or comparison stimulus, in drawing order; empty for every other stimulus.
    public let groups: [StimulusGroup]
    /// Gap between the two groups in dot pitches (0 when there is a single group).
    public let groupGap: Double

    public init(stimulus: QuestionStimulus) {
        identifier = SproutIdentifier.stimulus
        positions = stimulus.positions
        switch stimulus.detail {
        case let .groups(first: first, second: second), let .quantities(left: first, right: second):
            groups = [StimulusGroup(count: first), StimulusGroup(count: second)]
            groupGap = StimulusGroup.gapInPitches
        default:
            groups = []
            groupGap = 0
        }
        if case let .numberTrack(cells: cells, step: _) = stimulus.detail {
            trackValues = cells.map { $0.shape == .emptyOutline ? nil : $0.value }
        } else {
            trackValues = []
        }
        isTenFrame = stimulus.isTenFrame
        contrastMarkKind = stimulus.crossMark
        dotColourToken = "colour.dot"
        markColourToken = "colour.mark"
        haloColourToken = "colour.markHalo"
        accessibilityValueEN = stimulus.accessibilityValue(.en)
        accessibilityValueFR = stimulus.accessibilityValue(.fr)
        textEquivalentEN = stimulus.textEquivalent(.en)
        textEquivalentFR = stimulus.textEquivalent(.fr)
        _symbolNames = []
        comparisonSign = stimulus.comparisonUsesLarger.map { [$0 ? ">" : "<"] } ?? []
        formula = Self.formula(stimulus.detail)
        colourTokens = [dotColourToken, markColourToken, haloColourToken]
    }

    /// The visible formula of an addition or subtraction, such as "3 + 7 = ?"; nil for every other stimulus.
    static func formula(_ detail: StimulusDetail) -> String? {
        switch detail {
        case let .groups(first: first, second: second): return "\(first) + \(second) = ?"
        case let .dots(total: total, crossedOut: crossed): return "\(total) - \(crossed) = ?"
        default: return nil
        }
    }

    public func accessibilityValue(_ language: Language) -> String {
        language == .fr ? accessibilityValueFR : accessibilityValueEN
    }

    public func textEquivalent(_ language: Language) -> String {
        language == .fr ? textEquivalentFR : textEquivalentEN
    }
}

extension QuestionStimulus {
    public var presentation: StimulusPresentation { StimulusPresentation(stimulus: self) }

    /// The stimulus written out in words and numbers; the hidden track value stays a "?".
    public func textEquivalent(_ language: Language) -> String {
        let colon = TextTable.string("equiv.colon", language)
        switch detail {
        case .plain:
            return accessibilityValue(language)
        case let .groups(first: first, second: second):
            return "\(first) + \(second)" + colon + TextTable.string("equiv.groups", language)
        case let .dots(total: total, crossedOut: crossed):
            return "\(total) - \(crossed)" + colon + "\(crossed) " + TextTable.string("equiv.crossed-out", language)
        case let .numberTrack(cells: cells, step: _):
            let shown = cells.map { $0.shape == .emptyOutline ? "?" : String($0.value) }.joined(separator: ", ")
            return shown + colon + TextTable.string("equiv.empty-place", language)
        case let .quantities(left: left, right: right):
            return "\(left)" + TextTable.string("equiv.and", language) + "\(right)"
        }
    }
}

extension QuestionStimulus: CustomReflectable {
    public var customMirror: Mirror {
        Mirror(self, children: ["presentation": presentation])
    }
}
