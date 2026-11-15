/// Ordering: 2 to 5 tokens in a row; every token can move one place earlier or later by tap.
public struct KitOrdering: KitComponent {
    public private(set) var order: [String]
    public private(set) var announcements: [KitAnnouncement] = []

    public init(tokens: [String]) throws {
        guard (2...5).contains(tokens.count) else { throw KitError.tokenCount(tokens.count) }
        order = tokens
    }

    /// Removes the token at `from` and inserts it at `to`; out-of-range or equal positions change nothing.
    public mutating func move(from: Int, to: Int) {
        guard order.indices.contains(from), order.indices.contains(to), from != to else { return }
        let token = order.remove(at: from)
        order.insert(token, at: to)
        announcements.append(KitAnnouncement(key: "kit.say.moved", subject: token))
    }

    public mutating func apply(_ command: KitCommand) {
        switch command {
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
        order.enumerated().map { index, token in
            let command: KitCommand = index == order.count - 1 ? .moveEarlier(token) : .moveLater(token)
            return KitTapTarget(identifier: KitIdentifier.make("order", index), command: command, subject: token)
        }
    }
}
