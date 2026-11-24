/// Slot board: pick a token from the palette, tap a slot to fill it, tap a filled slot to take it back.
public struct KitSlotBoard: KitComponent {
    struct Step: Sendable, Equatable {
        let slot: Int
        let token: String
        let paletteIndex: Int
        let placed: Bool
        /// A reusable token stays in the palette, so undo has nothing to put back.
        var reusable = false
    }

    public private(set) var slots: [String?]
    public private(set) var palette: [String]
    public private(set) var selectedToken: String?
    public private(set) var announcements: [KitAnnouncement] = []
    private var history: [Step] = []

    public init(slotCount: Int, palette: [String]) {
        slots = Array(repeating: nil, count: min(max(slotCount, 1), 5))
        self.palette = palette
    }

    public var complete: Bool { slots.allSatisfy { $0 != nil } }
    /// The undo control is always shown; with nothing to undo it simply does nothing.
    public var undoVisible: Bool { true }
    /// Enabled whenever at least one tile was placed or taken back.
    public var undoEnabled: Bool { !history.isEmpty }
    /// The slots read left to right; the view draws an arrow so the direction is visible.
    public var showsDirection: Bool { true }

    public mutating func select(_ token: String) {
        guard palette.contains(token), selectedToken != token else { return }
        selectedToken = token
        announcements.append(KitAnnouncement(key: "kit.say.selected", subject: token))
    }

    public mutating func place(_ slot: Int) {
        guard slots.indices.contains(slot), slots[slot] == nil,
              let token = selectedToken, let index = palette.firstIndex(of: token) else { return }
        palette.remove(at: index)
        slots[slot] = token
        selectedToken = nil
        history.append(Step(slot: slot, token: token, paletteIndex: index, placed: true))
        announcements.append(KitAnnouncement(key: complete ? "kit.say.complete" : "kit.say.placed", subject: token))
    }

    /// Fills a slot with a palette token without using the token up, so a program can repeat a card.
    public mutating func placeReusable(_ token: String, at slot: Int) {
        guard slots.indices.contains(slot), slots[slot] == nil, palette.contains(token) else { return }
        slots[slot] = token
        selectedToken = nil
        history.append(Step(slot: slot, token: token, paletteIndex: 0, placed: true, reusable: true))
        announcements.append(KitAnnouncement(key: complete ? "kit.say.complete" : "kit.say.placed", subject: token))
    }

    public mutating func tapFilled(_ slot: Int) {
        guard slots.indices.contains(slot), let token = slots[slot] else { return }
        slots[slot] = nil
        palette.append(token)
        history.append(Step(slot: slot, token: token, paletteIndex: palette.count - 1, placed: false))
        announcements.append(KitAnnouncement(key: "kit.say.returned", subject: token))
    }

    public mutating func undo() {
        guard let step = history.popLast() else { return }
        if step.placed {
            slots[step.slot] = nil
            if !step.reusable { palette.insert(step.token, at: min(step.paletteIndex, palette.count)) }
        } else {
            palette.removeAll { $0 == step.token }
            slots[step.slot] = step.token
        }
        selectedToken = nil
        announcements.append(KitAnnouncement(key: "kit.say.undone", subject: step.token))
    }

    public mutating func apply(_ command: KitCommand) {
        switch command {
        case .select(let token): select(token)
        case .place(let slot): place(slot)
        case .tapFilled(let slot): tapFilled(slot)
        case .undo: undo()
        default: break
        }
    }

    public var accessibilityActions: [KitAccessibilityAction] {
        var list = palette.map { KitAccessibilityAction(labelKey: "kit.action.select", command: .select($0), subject: $0) }
        for (index, slot) in slots.enumerated() {
            if let token = slot {
                list.append(KitAccessibilityAction(labelKey: "kit.action.return", command: .tapFilled(index), subject: token))
            } else if selectedToken != nil {
                list.append(KitAccessibilityAction(labelKey: "kit.action.place", command: .place(index)))
            }
        }
        list.append(KitAccessibilityAction(labelKey: "kit.action.undo", command: .undo))
        return list
    }

    public var tapTargets: [KitTapTarget] {
        var list: [KitTapTarget] = []
        for (index, slot) in slots.enumerated() {
            list.append(KitTapTarget(identifier: KitIdentifier.make("slot", index),
                                     command: slot == nil ? .place(index) : .tapFilled(index), subject: slot))
        }
        for (index, token) in palette.enumerated() {
            list.append(KitTapTarget(identifier: KitIdentifier.make("palette", index),
                                     command: .select(token), subject: token))
        }
        list.append(KitTapTarget(identifier: KitIdentifier.make("undo"), command: .undo))
        return list
    }
}
