public enum KitTileKind: Sendable, Equatable {
    case letter, syllable
}

/// A row of letter or syllable tiles; the selected tile is highlighted in the activity colour.
/// A set made with `splitGrapheme` joins its two letter tiles into one unit once both were tapped.
/// A set made with `letters:pair:` holds every letter of a word; two adjacent taps pick the pair.
/// A set made with `chunks:` holds movable pieces of a word that the child puts back in order.
public struct KitTileSet: KitComponent {
    public let kind: KitTileKind
    public private(set) var tiles: [String]
    public let highlightColourToken: ActivityColourToken
    public private(set) var selectedToken: String?
    public private(set) var announcements: [KitAnnouncement] = []
    /// The letters tapped so far in a pair set (at most two); empty in other sets.
    public private(set) var pickedLetters: [String] = []
    private let splitLetters: [String]
    private let pairTarget: String?
    private let movable: Bool
    private var tappedLetters: [String] = []

    public init(kind: KitTileKind, tiles: [String], colourToken: ActivityColourToken) {
        self.kind = kind
        self.tiles = tiles
        highlightColourToken = colourToken
        splitLetters = []
        pairTarget = nil
        movable = false
    }

    /// A deliberately split grapheme: its letters shown as separate tiles, to be joined back into one.
    public init(splitGrapheme letters: [String], colourToken: ActivityColourToken) {
        kind = .letter
        tiles = letters
        highlightColourToken = colourToken
        splitLetters = letters
        pairTarget = nil
        movable = false
    }

    /// Every letter of a word as its own tile; the child taps the two letters of `pair`.
    public init(letters word: String, pair: String, colourToken: ActivityColourToken) {
        kind = .letter
        tiles = word.map { String($0) }
        highlightColourToken = colourToken
        splitLetters = []
        pairTarget = pair
        movable = false
    }

    /// Movable pieces of a word, in the order shown.
    public init(chunks: [String], colourToken: ActivityColourToken) {
        kind = .syllable
        tiles = chunks
        highlightColourToken = colourToken
        splitLetters = []
        pairTarget = nil
        movable = true
    }

    /// True once two adjacent letters spelling the pair were picked.
    public var pairPicked: Bool {
        guard let target = pairTarget, pickedLetters.count == 2 else { return false }
        let places = pickedLetters.compactMap { tiles.firstIndex(of: $0) }.sorted()
        guard places.count == 2, places[1] == places[0] + 1 else { return false }
        return places.map { tiles[$0] }.joined() == target
    }

    public mutating func select(_ token: String) {
        guard tiles.contains(token), selectedToken != token || pairTarget != nil, !movable else { return }
        if pairTarget != nil { return pick(token) }
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

    private mutating func pick(_ token: String) {
        guard !pickedLetters.contains(token) || pickedLetters.count == 2 else { return }
        if pickedLetters.count == 2 { pickedLetters = [] }
        pickedLetters.append(token)
        selectedToken = token
        announcements.append(KitAnnouncement(key: "kit.say.selected", subject: token))
    }

    private mutating func move(_ token: String, by step: Int) {
        guard let index = tiles.firstIndex(of: token), tiles.indices.contains(index + step) else { return }
        tiles.swapAt(index, index + step)
        announcements.append(KitAnnouncement(key: "kit.say.moved", subject: token))
    }

    public mutating func apply(_ command: KitCommand) {
        switch command {
        case .select(let token): select(token)
        case .moveEarlier(let token) where movable: move(token, by: -1)
        case .moveLater(let token) where movable: move(token, by: 1)
        default: break
        }
    }

    public var accessibilityActions: [KitAccessibilityAction] {
        guard movable else {
            return tiles.map { KitAccessibilityAction(labelKey: "kit.action.select", command: .select($0), subject: $0) }
        }
        return tiles.flatMap { token in
            [KitAccessibilityAction(labelKey: "kit.action.earlier", command: .moveEarlier(token), subject: token),
             KitAccessibilityAction(labelKey: "kit.action.later", command: .moveLater(token), subject: token)]
        }
    }

    public var tapTargets: [KitTapTarget] {
        let width = kind == .syllable ? KitMetrics.wideTarget : KitMetrics.minTarget
        return tiles.enumerated().map { index, token in
            // A tap on a chunk sends it later; the last chunk has nowhere later to go, so it moves earlier.
            let command: KitCommand = movable
                ? (index == tiles.count - 1 ? .moveEarlier(token) : .moveLater(token)) : .select(token)
            return KitTapTarget(identifier: KitIdentifier.make("tile", index), command: command, subject: token,
                                size: (width, KitMetrics.minTarget))
        }
    }
}
