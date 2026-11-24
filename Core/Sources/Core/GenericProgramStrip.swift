import Foundation

/// One event or a pair of events played two to five times.
public struct RepeatBlock<Event: Hashable & Sendable & RawRepresentable<String>>: Sendable {
    public static var countRange: ClosedRange<Int> { 2...5 }

    public let events: [Event]
    public var count: Int { didSet { count = Self.clamp(count) } }

    public init(count: Int, events: [Event]) {
        self.count = Self.clamp(count)
        self.events = Array(events.prefix(2))
    }

    private static func clamp(_ value: Int) -> Int {
        min(max(value, countRange.lowerBound), countRange.upperBound)
    }

    public var expanded: [Event] { Array((0..<count).map { _ in events }.joined()) }
}

/// A program strip over any string-backed event type, built on the interaction kit slot board.
public struct GenericProgramStrip<Event: Hashable & Sendable & RawRepresentable<String>>: Sendable {
    public private(set) var board: KitSlotBoard
    public private(set) var playhead = 0
    /// Repeat blocks with the number of plain cards that come before each one.
    public private(set) var repeats: [(after: Int, block: RepeatBlock<Event>)] = []

    public init(slotCount: Int, palette: [Event]) {
        board = KitSlotBoard(slotCount: slotCount, palette: palette.map(\.rawValue))
    }

    public var cards: [Event] { board.slots.compactMap { $0.flatMap(Event.init(rawValue:)) } }
    public var undoVisible: Bool { board.undoVisible }

    public mutating func add(_ event: Event) {
        guard hasFreeSlot, let slot = board.slots.firstIndex(where: { $0 == nil }) else { return }
        board.placeReusable(event.rawValue, at: slot)
    }

    /// A repeat block takes one slot, after the cards already placed.
    public mutating func addRepeat(_ block: RepeatBlock<Event>) {
        guard hasFreeSlot, !block.events.isEmpty else { return }
        repeats.append((after: cards.count, block: block))
    }

    private var hasFreeSlot: Bool {
        cards.count + repeats.count < board.slots.count
    }

    /// The flat event list: plain cards in order with each repeat block unrolled in place.
    public func expanded() -> [Event] {
        let plain = cards
        var result: [Event] = []
        for index in 0...plain.count {
            for entry in repeats where min(entry.after, plain.count) == index {
                result += entry.block.expanded
            }
            if index < plain.count { result.append(plain[index]) }
        }
        return result
    }

    public mutating func step() -> Event? {
        let program = expanded()
        guard playhead < program.count else { return nil }
        playhead += 1
        return program[playhead - 1]
    }

    public mutating func play() -> [Event] {
        var played: [Event] = []
        while let event = step() { played.append(event) }
        return played
    }

    public mutating func rewind() { playhead = 0 }
    public mutating func reset() { playhead = 0 }

    public mutating func undo() {
        board.undo()
        playhead = min(playhead, expanded().count)
    }
}
