/// Everything a trail tile view draws and speaks; the views hard-code none of it.
public struct TrailTilePresentation: Sendable, Equatable {
    public let state: TrailState
    public let identifier: String
    public let title: String
    public let accessibilityLabel: String
    public let identities: [ActivityIdentity]
    /// Symbol of the state glyph (play, lock or check).
    public let stateSymbolName: String
    /// Lock symbol; non-nil only for a locked tile.
    public let lockIcon: String?
    /// The level that must be completed first; non-nil only for a locked tile.
    public let requiresLevelId: String?
    public let stateColourToken: String
    public let isHighlighted: Bool
    public let showsReviewMarker: Bool
    public let reviewSymbolName: String?
    public let highlightSymbolName: String?
    public let isEnabled: Bool
    public let symbolNames: [String]
    public let colourTokens: [String]

    public init(level: LevelDefinition, record: ProgressRecord, language: Language) {
        let state = TrailState.resolve(level: level, previous: level.prerequisites.last, record: record)
        self.init(level: level, state: state, language: language)
    }

    init(level: LevelDefinition, state: TrailState, language: Language) {
        self.state = state
        identifier = SproutIdentifier.level(level.levelId)
        title = language == .fr ? level.titleFR : level.titleEN
        accessibilityLabel = title + TextTable.string("equiv.colon", language)
            + TextTable.string(Self.stateKey(state), language)
        identities = level.activityIdentities
        if case let .locked(requires: previous) = state {
            lockIcon = ChromeCatalog.lockedSymbolName
            requiresLevelId = previous
        } else {
            lockIcon = nil
            requiresLevelId = nil
        }
        stateSymbolName = Self.stateSymbol(state)
        stateColourToken = Self.stateColour(state)
        isHighlighted = state == .suggested
        showsReviewMarker = state == .dueForReview
        highlightSymbolName = state == .suggested ? ChromeCatalog.suggestedSymbolName : nil
        reviewSymbolName = state == .dueForReview ? ChromeCatalog.reviewSymbolName : nil
        isEnabled = lockIcon == nil
        symbolNames = [stateSymbolName] + [highlightSymbolName, reviewSymbolName].compactMap { $0 }
            + identities.map { ChromeCatalog.activitySymbolName($0.iconKind) }
            + (level.track == "music" ? [ChromeCatalog.symbolName(for: .note)] : [])
        colourTokens = [stateColourToken, level.colourName]
    }

    private static func stateKey(_ state: TrailState) -> String {
        switch state {
        case .locked: return "trail.state.locked"
        case .open: return "trail.state.open"
        case .suggested: return "trail.state.suggested"
        case .completed: return "trail.state.completed"
        case .dueForReview: return "trail.state.review"
        }
    }

    private static func stateSymbol(_ state: TrailState) -> String {
        switch state {
        case .locked: return ChromeCatalog.lockedSymbolName
        case .open, .suggested: return ChromeCatalog.symbolName(for: .play)
        case .completed, .dueForReview: return ChromeCatalog.symbolName(for: .check)
        }
    }

    private static func stateColour(_ state: TrailState) -> String {
        switch state {
        case .locked: return "colour.locked"
        case .open: return "colour.accent"
        case .suggested: return "colour.suggested"
        case .completed: return "colour.green"
        case .dueForReview: return "colour.review"
        }
    }
}

extension TrailState {
    /// The state of a level given the level before it in its lane (nil for the first).
    static func resolve(level: LevelDefinition, previous: String?, record: ProgressRecord) -> TrailState {
        if (record.progress(for: level.levelId)?.completions ?? 0) >= 1 {
            return ReviewScheduler.isDue(level.levelId, record: record) ? .dueForReview : .completed
        }
        guard let previous else { return .open }
        guard (record.progress(for: previous)?.completions ?? 0) >= 1 else { return .locked(requires: previous) }
        return MasteryPolicy.suggestsNext(level: previous, record: record) ? .suggested : .open
    }
}

extension TextTable {
    static let trailStateTexts: [String: TextEntry] = [
        "trail.state.locked": TextEntry("verrouillé", "locked"),
        "trail.state.open": TextEntry("ouvert", "open"),
        "trail.state.suggested": TextEntry("suggéré", "suggested"),
        "trail.state.completed": TextEntry("terminé", "completed"),
        "trail.state.review": TextEntry("à réviser", "due for review")
    ]
}
