import Foundation

/// C1: step, predict the end cell, then play. The round always ends with three stars.
public struct RobotC1Round: Equatable, Sendable {
    public let presentation: RobotC1Presentation
    public private(set) var position: GridPoint
    public private(set) var prediction: GridPoint?
    public private(set) var isComplete = false
    private var stepsTaken = 0

    public init(presentation: RobotC1Presentation) {
        self.presentation = presentation
        self.position = presentation.world.start
    }

    /// The state a stop opens: one step taken, so the prediction choices show next to the grid.
    public static func auditStop(seed: UInt64) -> RobotC1Round {
        var round = RobotC1Round(presentation: RobotC1Presentation.make(seed: seed))
        _ = round.step()
        return round
    }

    public var stars: Int { isComplete ? ProgressRecord.starsPerRound : 0 }
    public var playEnabled: Bool { prediction != nil && !isComplete }

    /// Empty until a step was taken; then the end cell and two other cells, in a fixed order.
    public var predictionChoices: [GridPoint] {
        guard stepsTaken > 0 else { return [] }
        let world = presentation.world
        let end = presentation.endCell
        let cells = (0..<world.width * world.height).map { GridPoint($0 % world.width, $0 / world.width) }
        let others = cells.filter { $0 != end }
        let shift = (end.x + end.y * world.width) % max(others.count, 1)
        let rotated = Array(others[shift...] + others[..<shift])
        return [end] + rotated.prefix(2)
    }

    public mutating func step() -> GridEvent? {
        guard !isComplete, stepsTaken < presentation.cards.count else { return nil }
        position = presentation.world.next(from: position, presentation.cards[stepsTaken])
        stepsTaken += 1
        return .moved(position)
    }

    public mutating func predict(_ cell: GridPoint) {
        guard stepsTaken > 0, !isComplete else { return }
        prediction = cell
    }

    public mutating func play() {
        guard playEnabled else { return }
        position = presentation.endCell
        stepsTaken = presentation.cards.count
        isComplete = true
    }
}

/// C2: fill empty slots from the palette, predict, then step or play.
public struct RobotC2Round: Equatable, Sendable {
    public let world: GridWorld
    public let slotCount: Int
    public let palette = GridMove.allCases
    public private(set) var program: [GridMove] = []
    public private(set) var prediction: GridPoint?
    public private(set) var position: GridPoint
    public private(set) var isComplete = false
    private var stepsTaken = 0

    public init(world: GridWorld, slotCount: Int) {
        self.world = world
        self.slotCount = slotCount
        self.position = world.start
    }

    public var stars: Int { isComplete ? ProgressRecord.starsPerRound : 0 }
    public var isFull: Bool { program.count == slotCount }
    public var stepEnabled: Bool { isFull && prediction != nil && !isComplete }
    public var playEnabled: Bool { stepEnabled }

    public mutating func add(_ move: GridMove) {
        guard !isFull, !isComplete else { return }
        program.append(move)
        reset()
    }

    public mutating func undo() {
        guard !program.isEmpty, !isComplete else { return }
        program.removeLast()
        reset()
    }

    public mutating func predict(_ cell: GridPoint) {
        guard !isComplete else { return }
        prediction = cell
    }

    public mutating func step() -> GridEvent? {
        guard stepEnabled else { return nil }
        let next = world.next(from: position, program[stepsTaken])
        if world.isBlocked(next) {
            reset()
            return .blocked
        }
        position = next
        stepsTaken += 1
        if stepsTaken == program.count {
            if position == world.goal { isComplete = true } else { reset() }
        }
        return .moved(next)
    }

    public mutating func play() {
        guard stepEnabled else { return }
        var event = step()
        while !isComplete, case .moved? = event, stepsTaken > 0 { event = step() }
    }

    private mutating func reset() {
        position = world.start
        stepsTaken = 0
    }
}

/// C3: one card of the program is off; the ant marks it and the child swaps it.
public struct RobotC3Round: Equatable, Sendable {
    public let presentation: RobotC3Presentation
    public private(set) var cards: [GridMove]
    public private(set) var antIndex: Int?
    public private(set) var isComplete = false

    public init(presentation: RobotC3Presentation) {
        self.presentation = presentation
        self.cards = presentation.cards
    }

    public var stars: Int { isComplete ? ProgressRecord.starsPerRound : 0 }
    /// The card the marker sits on; the same value as `antIndex`.
    public var markerIndex: Int? { antIndex }

    public mutating func swap(index: Int, to move: GridMove) {
        guard cards.indices.contains(index), !isComplete else { return }
        cards[index] = move
    }

    public mutating func play() {
        guard !isComplete else { return }
        if RobotRoute.end(presentation.world, cards) == presentation.world.goal {
            isComplete = true
            antIndex = nil
        } else {
            antIndex = cards.indices.first { cards[$0] != presentation.fixedCards[$0] }
        }
    }
}
