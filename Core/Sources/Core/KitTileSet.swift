public enum KitTileKind: Sendable, Equatable {
    case letter, syllable
}

/// A row of letter or syllable tiles; the selected tile is highlighted in the activity colour.
/// A set made with `splitGrapheme` joins its two letter tiles into one unit once both were tapped.
public struct KitTileSet: KitComponent {
    public let kind: KitTileKind
    public private(set) var tiles: [String]
    public let highlightColourToken: ActivityColourToken
    public private(set) var selectedToken: String?
    public private(set) var announcements: [KitAnnouncement] = []
    private let splitLetters: [String]
    private var tappedLetters: [String] = []

    public init(kind: KitTileKind, tiles: [String], colourToken: ActivityColourToken) {
        self.kind = kind
        self.tiles = tiles
        highlightColourToken = colourToken
        splitLetters = []
    }

    /// A deliberately split grapheme: its letters shown as separate tiles, to be joined back into one.
    public init(splitGrapheme letters: [String], colourToken: ActivityColourToken) {
        kind = .letter
        tiles = letters
        highlightColourToken = colourToken
        splitLetters = letters
    }

    public mutating func select(_ token: String) {
        guard tiles.contains(token), selectedToken != token else { return }
        selectedToken = token
        announcements.append(KitAnnouncement(key: "kit.say.selected", subject: token))
        guard splitLetters.count > 1, splitLetters.contains(token), !tappedLetters.contains(token) else { return }
        tappedLetters.append(token)
        if tappedLetters.count == splitLetters.count {
            let joined = splitLetters.joined()
            tiles = [joined]
            selectedToken = joined
            announcements.append(KitAnnouncement(key: "kit.say.complete", subject: joined))
        }
    }

    public mutating func apply(_ command: KitCommand) {
        if case .select(let token) = command { select(token) }
    }

    public var accessibilityActions: [KitAccessibilityAction] {
        tiles.map { KitAccessibilityAction(labelKey: "kit.action.select", command: .select($0), subject: $0) }
    }

    public var tapTargets: [KitTapTarget] {
        let width = kind == .syllable ? KitMetrics.wideTarget : KitMetrics.minTarget
        return tiles.enumerated().map { index, token in
            KitTapTarget(identifier: KitIdentifier.make("tile", index), command: .select(token), subject: token,
                         size: (width, KitMetrics.minTarget))
        }
    }
}
