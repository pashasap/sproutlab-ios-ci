import Foundation

/// C4: a repeat block replaces a run of identical arrows. Rounds 1...4; round 4 asks for the end cell.
public struct RobotC4Presentation: Sendable {
    public static let slotCount = 10
    public let round: Int
    public let world: GridWorld
    public let block: RepeatBlock<GridMove>
    public let plainBefore: [GridMove]

    public var isPredictRound: Bool { round == 4 }

    /// The plain cards first, then the repeat block as one slot.
    public var looped: GenericProgramStrip<GridMove> {
        var strip = GenericProgramStrip<GridMove>(slotCount: Self.slotCount, palette: GridMove.allCases)
        for move in plainBefore { strip.add(move) }
        strip.addRepeat(block)
        return strip
    }

    public var expandedProgram: [GridMove] { plainBefore + block.expanded }

    public var endCell: GridPoint { RobotC4Route.cells(world, expandedProgram).last ?? world.start }

    public static func make(round: Int, seed: UInt64) -> RobotC4Presentation {
        let number = min(max(round, 1), 4)
        var rng = SeededRandom(seed: seed ^ UInt64(0xC4C4 + number))
        switch number {
        case 1: return makeSingle(number, &rng)
        case 2: return makeStaircase(number, &rng)
        case 3: return makeObstacle(number, &rng)
        default: return makePredict(number, &rng)
        }
    }

    /// The shape of one round: grid side, start cell, plain cards and the repeat block.
    private struct Spec {
        let round: Int
        let side: Int
        let start: GridPoint
        let before: [GridMove]
        let block: RepeatBlock<GridMove>
    }

    private static func build(_ spec: Spec, rocks: (GridPoint) -> [GridPoint]) -> RobotC4Presentation {
        let side = spec.side
        let open = GridWorld(width: side, height: side, start: spec.start, goal: spec.start)
        let goal = RobotC4Route.cells(open, spec.before + spec.block.expanded).last ?? spec.start
        var world = GridWorld(width: side, height: side, start: spec.start, goal: goal)
        for rock in rocks(goal) { world.addRock(rock) }
        return RobotC4Presentation(round: spec.round, world: world, block: spec.block,
                                   plainBefore: spec.before)
    }

    private static func makeSingle(_ round: Int, _ rng: inout SeededRandom) -> RobotC4Presentation {
        let move: GridMove = rng.below(2) == 0 ? .right : .down
        let before: [GridMove] = rng.below(2) == 0 ? [] : [move == .right ? .down : .right]
        let block = RepeatBlock<GridMove>(count: 4, events: [move])
        return build(Spec(round: round, side: 6, start: GridPoint(0, 0), before: before, block: block)) { _ in [] }
    }

    private static func makeStaircase(_ round: Int, _ rng: inout SeededRandom) -> RobotC4Presentation {
        let before: [GridMove] = rng.below(2) == 0 ? [] : [.right]
        let block = RepeatBlock<GridMove>(count: 2, events: [.right, .up])
        return build(Spec(round: round, side: 6, start: GridPoint(0, 5), before: before, block: block)) { _ in [] }
    }

    private static func makeObstacle(_ round: Int, _ rng: inout SeededRandom) -> RobotC4Presentation {
        let count = 2 + rng.below(2)
        let block = RepeatBlock<GridMove>(count: count, events: [.right])
        let spec = Spec(round: round, side: 5, start: GridPoint(0, 0), before: [.down], block: block)
        return build(spec) { goal in [GridPoint(goal.x, goal.y + 1)] }
    }

    private static func makePredict(_ round: Int, _ rng: inout SeededRandom) -> RobotC4Presentation {
        let pair = rng.below(2) == 0
        let block = pair ? RepeatBlock<GridMove>(count: 2, events: [.right, .down])
                         : RepeatBlock<GridMove>(count: 2 + rng.below(3), events: [.right])
        let spec = Spec(round: round, side: 7, start: GridPoint(0, 0), before: [.down], block: block)
        return build(spec) { _ in [] }
    }
}

enum RobotC4Route {
    static func cells(_ world: GridWorld, _ moves: [GridMove]) -> [GridPoint] {
        RobotRoute.cells(world, moves)
    }
}

/// The long program and the looped one side by side: same trace, same path.
public struct RobotC4PairView: Sendable {
    public let expandedStrip: GenericProgramStrip<GridMove>
    public let loopedStrip: GenericProgramStrip<GridMove>
    public let expandedProgram: [GridMove]
    public let expandedTrace: [GridEvent]
    public let loopedTrace: [GridEvent]
    public let expandedPath: [GridPoint]
    public let loopedPath: [GridPoint]

    public init(presentation: RobotC4Presentation) {
        let world = presentation.world
        var long = GenericProgramStrip<GridMove>(slotCount: RobotC4Presentation.slotCount,
                                                 palette: GridMove.allCases)
        for move in presentation.expandedProgram { long.add(move) }
        expandedStrip = long
        loopedStrip = presentation.looped
        expandedProgram = presentation.expandedProgram
        var longRun = GridInterpreter(world: world, strip: long)
        longRun.play()
        var shortRun = GridInterpreter(world: world, strip: presentation.looped)
        shortRun.play()
        expandedTrace = longRun.trace
        loopedTrace = shortRun.trace
        expandedPath = Self.path(world, longRun.trace)
        loopedPath = Self.path(world, shortRun.trace)
    }

    private static func path(_ world: GridWorld, _ trace: [GridEvent]) -> [GridPoint] {
        var cells = [world.start]
        for event in trace {
            switch event {
            case .moved(let cell), .collected(let cell): cells.append(cell)
            case .blocked, .finished: break
            }
        }
        return cells
    }
}

public enum RobotC4HelpKind: Equatable, Sendable {
    case mark, block, dotCountDemo
}

public struct RobotC4HelpStep: Equatable, Sendable {
    public let kind: RobotC4HelpKind
    public let markedIndices: [Int]
    public let blockEvents: [GridMove]
    public let demoCounts: [Int]
}

public enum RobotC4Help {
    /// Mark the repeated arrows, show the block around one unit, demo the dot count.
    public static func steps(for presentation: RobotC4Presentation) -> [RobotC4HelpStep] {
        let start = presentation.plainBefore.count
        let marked = Array(start..<(start + presentation.block.events.count * presentation.block.count))
        return [
            RobotC4HelpStep(kind: .mark, markedIndices: marked, blockEvents: [], demoCounts: []),
            RobotC4HelpStep(kind: .block, markedIndices: [], blockEvents: presentation.block.events, demoCounts: []),
            RobotC4HelpStep(kind: .dotCountDemo, markedIndices: [], blockEvents: [],
                            demoCounts: Array(RepeatBlock<GridMove>.countRange))
        ]
    }
}

/// One C4 round: no fail state, no star loss; a wrong cell only offers the next hint.
public struct RobotC4Round: Sendable {
    public let presentation: RobotC4Presentation
    public private(set) var isComplete = false
    public private(set) var hintLevel = 0

    public init(presentation: RobotC4Presentation) { self.presentation = presentation }

    public var stars: Int { isComplete ? ProgressRecord.starsPerRound : 0 }
    public var hasFailed: Bool { false }
    public var starsLost: Int { 0 }

    public var nextHint: RobotC4HelpStep? {
        hintLevel > 0 ? RobotC4Help.steps(for: presentation)[hintLevel - 1] : nil
    }

    /// The end cell and two other cells in the grid; empty outside the predict round.
    public var predictionChoices: [GridPoint] {
        guard presentation.isPredictRound else { return [] }
        let world = presentation.world
        let end = presentation.endCell
        let cells = (0..<world.width * world.height).map { GridPoint($0 % world.width, $0 / world.width) }
        let others = cells.filter { $0 != end && $0 != world.start }
        let shift = (end.x + end.y * world.width) % max(others.count, 1)
        return [end] + Array((others[shift...] + others[..<shift]).prefix(2))
    }

    public mutating func play() {
        guard !presentation.isPredictRound else { return }
        isComplete = true
    }

    public mutating func submit(_ cell: GridPoint) {
        guard presentation.isPredictRound, !isComplete else { return }
        if cell == presentation.endCell { isComplete = true } else { hintLevel = min(hintLevel + 1, 3) }
    }
}

/// The repeat dots: counts 2...5, each at least 56 points, each with its own spoken name.
public struct RepeatControlsPresentation: Equatable, Sendable {
    public let dotCounts: [Int]
    public let minDotSide: Double

    public static let standard = RepeatControlsPresentation(
        dotCounts: Array(RepeatBlock<GridMove>.countRange), minDotSide: RobotLayout.repeatDotSide)

    public func accessibleName(count: Int, _ language: Language) -> String {
        language == .fr ? "Répète \(count) fois" : "Repeat \(count) times"
    }
}
