import Foundation

/// A program strip over any string-backed event type, built on the interaction kit slot board.
public struct GenericProgramStrip<Event: Hashable & Sendable & RawRepresentable<String>>: Sendable {
    public private(set) var board: KitSlotBoard
    public private(set) var playhead = 0

    public init(slotCount: Int, palette: [Event]) {
        board = KitSlotBoard(slotCount: slotCount, palette: palette.map(\.rawValue))
    }

    public var cards: [Event] { board.slots.compactMap { $0.flatMap(Event.init(rawValue:)) } }
    public var undoVisible: Bool { board.undoVisible }

    public mutating func add(_ event: Event) {
        guard let slot = board.slots.firstIndex(where: { $0 == nil }) else { return }
        board.select(event.rawValue)
        board.place(slot)
    }

    public mutating func step() -> Event? {
        let program = cards
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
        playhead = min(playhead, cards.count)
    }
}
