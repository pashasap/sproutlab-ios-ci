/// Ordering: 2 to 5 tokens in a row; every token can move one place earlier or later by tap.
public struct KitOrdering: KitComponent {
    public private(set) var order: [String]
    public private(set) var announcements: [KitAnnouncement] = []
    private var history: [[String]] = []

    public init(tokens: [String]) throws {
        guard (2...5).contains(tokens.count) else { throw KitError.tokenCount(tokens.count) }
        order = tokens
    }

    /// Removes the token at `from` and inserts it at `to`; out-of-range or equal positions change nothing.
    public mutating func move(from: Int, to: Int) {
        guard order.indices.contains(from), order.indices.contains(to), from != to else { return }
        history.append(order)
        let token = order.remove(at: from)
        order.insert(token, at: to)
        announcements.append(KitAnnouncement(key: "kit.say.moved", subject: token))
    }

    /// Tap-to-place: puts `token` at position `index`; the same result as dragging it there.
    public mutating func place(_ token: String, at index: Int) {
        guard let from = order.firstIndex(of: token) else { return }
        move(from: from, to: index)
    }

    /// Restores the order before the last move; nothing to undo changes nothing.
    public mutating func undo() {
        guard let previous = history.popLast() else { return }
        order = previous
        announcements.append(KitAnnouncement(key: "kit.say.undone"))
    }

    /// The undo control is always shown.
    public var undoVisible: Bool { true }
    public var undoEnabled: Bool { !history.isEmpty }

    public mutating func apply(_ command: KitCommand) {
        switch command {
        case .undo: undo()
        case .moveEarlier(let token):
            if let index = order.firstIndex(of: token) { move(from: index, to: index - 1) }
        case .moveLater(let token):
            if let index = order.firstIndex(of: token) { move(from: index, to: index + 1) }
        default: break
        }
    }

    public var accessibilityActions: [KitAccessibilityAction] {
        order.flatMap { token in
            [KitAccessibilityAction(labelKey: "kit.action.earlier", command: .moveEarlier(token), subject: token),
             KitAccessibilityAction(labelKey: "kit.action.later", command: .moveLater(token), subject: token)]
        }
    }

    public var tapTargets: [KitTapTarget] {
        // A tap sends a token later; the last token has nowhere later to go, so it moves earlier.
        let tiles = order.enumerated().map { index, token in
            let command: KitCommand = index == order.count - 1 ? .moveEarlier(token) : .moveLater(token)
            return KitTapTarget(identifier: KitIdentifier.make("order", index), command: command, subject: token)
        }
        return tiles + [KitTapTarget(identifier: KitIdentifier.make("undo"), command: .undo)]
    }
}
