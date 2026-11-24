import Foundation

/// What the C4 strip draws for the repeat block.
public struct RobotC4RepeatBlockView: Equatable, Sendable {
    public let arrows: [GridMove]
    public let iconId: String
    public let badge: String
}

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

    /// The repeat block as the screen draws it: wrapped arrows, a registered icon and the xN badge.
    public var repeatBlock: RobotC4RepeatBlockView {
        RobotC4RepeatBlockView(arrows: block.events, iconId: "icon.repeat", badge: "x\(block.count)")
    }

    /// The same round with the repeat count changed (clamped to 2...5).
    func withRepeatCount(_ count: Int) -> RobotC4Presentation {
        var copy = block
        copy.count = count
        let open = GridWorld(width: world.width, height: world.height, start: world.start, goal: world.start)
        let goal = RobotC4Route.cells(open, plainBefore + copy.expanded).last ?? world.start
        var moved = GridWorld(width: world.width, height: world.height, start: world.start, goal: goal)
        for rock in world.rocks {
            moved.addRock(GridPoint(rock.x + goal.x - world.goal.x, rock.y + goal.y - world.goal.y))
        }
        return RobotC4Presentation(round: round, world: moved, block: copy, plainBefore: plainBefore)
    }

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
        // The slot board holds at most five cards, so the long trace is simulated from the move list.
        let longTrace = GridInterpreter.simulate(world: world, program: presentation.expandedProgram)
        var shortRun = GridInterpreter(world: world, strip: presentation.looped)
        shortRun.play()
        expandedTrace = longTrace
        loopedTrace = shortRun.trace
        expandedPath = Self.path(world, longTrace)
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
    public private(set) var presentation: RobotC4Presentation
    public private(set) var isComplete = false
    public private(set) var hintLevel = 0
    public private(set) var repeatCount: Int
    public private(set) var trace: [GridEvent]
    public private(set) var robotPosition: GridPoint
    private var stepIndex = 0

    public init(presentation: RobotC4Presentation) {
        self.presentation = presentation
        repeatCount = presentation.block.count
        trace = Self.trace(of: presentation)
        robotPosition = presentation.world.start
    }

    private static func trace(of presentation: RobotC4Presentation) -> [GridEvent] {
        var run = GridInterpreter(world: presentation.world, strip: presentation.looped)
        run.play()
        return run.trace
    }

    /// Clamp to 2...5, rebuild the programs and the trace, and put the robot back on the start cell.
    public mutating func setRepeatCount(_ count: Int) {
        presentation = presentation.withRepeatCount(count)
        repeatCount = presentation.block.count
        trace = Self.trace(of: presentation)
        stepIndex = 0
        robotPosition = presentation.world.start
    }

    /// Move the robot one trace event along.
    public mutating func step() {
        guard stepIndex < trace.count else { return }
        switch trace[stepIndex] {
        case .moved(let cell), .collected(let cell): robotPosition = cell
        case .blocked, .finished: break
        }
        stepIndex += 1
    }

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
        while stepIndex < trace.count { step() }
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
