import Foundation

public enum TraceComparison {
    /// Index of the first event where the two traces differ, or nil when they are equal.
    public static func firstDivergence<E: Equatable>(planned: [E], actual: [E]) -> Int? {
        let shared = min(planned.count, actual.count)
        for index in 0..<shared where planned[index] != actual[index] { return index }
        return planned.count == actual.count ? nil : shared
    }
}

/// Runs a move program on a grid. The program is only read, so a failed run never changes it.
public struct GridInterpreter: Sendable {
    public let world: GridWorld
    public private(set) var strip: GenericProgramStrip<GridMove>
    public private(set) var position: GridPoint
    public private(set) var trace: [GridEvent] = []
    private var halted = false

    public init(world: GridWorld, strip: GenericProgramStrip<GridMove>) {
        self.world = world
        self.strip = strip
        position = world.start
    }

    public var program: [GridMove] { strip.expanded() }
    public var playhead: Int { strip.playhead }

    public static func apply(_ move: GridMove, at position: GridPoint, in world: GridWorld) -> (GridPoint, GridEvent) {
        let target = world.next(from: position, move)
        if world.isBlocked(target) { return (position, .blocked) }
        return (target, world.items.contains(target) ? .collected(target) : .moved(target))
    }

    public mutating func step() -> GridEvent? {
        guard !halted, let move = strip.step() else { return nil }
        let (cell, event) = Self.apply(move, at: position, in: world)
        position = cell
        trace.append(event)
        if event == .blocked {
            halted = true
        } else if strip.playhead == program.count, position == world.goal {
            trace.append(.finished)
        }
        return event
    }

    public mutating func play() {
        while step() != nil {}
    }

    public mutating func rewind() { restart() }
    public mutating func reset() { restart() }

    public mutating func undo() { strip.undo() }

    private mutating func restart() {
        strip.rewind()
        position = world.start
        trace = []
        halted = false
    }

    public static func simulate(world: GridWorld, program: [GridMove]) -> [GridEvent] {
        var position = world.start
        var trace: [GridEvent] = []
        for move in program {
            let (cell, event) = apply(move, at: position, in: world)
            trace.append(event)
            if event == .blocked { return trace }
            position = cell
        }
        if position == world.goal { trace.append(.finished) }
        return trace
    }
}

public enum GridVerifier {
    /// Accepts any program that reaches the goal without being blocked, not one canonical route.
    public static func accepts(world: GridWorld, program: [GridMove]) -> Bool {
        let trace = GridInterpreter.simulate(world: world, program: program)
        return trace.last == .finished && !trace.contains(.blocked)
    }
}
