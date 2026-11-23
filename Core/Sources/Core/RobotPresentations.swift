import Foundation

/// Walks arrow cards over a grid: the one rule every robot level shares.
public enum RobotRoute {
    /// The cell after `cards`; nil when a card leaves the grid or meets a rock.
    public static func end(_ world: GridWorld, _ cards: [GridMove]) -> GridPoint? {
        var cell = world.start
        for card in cards {
            cell = world.next(from: cell, card)
            if world.isBlocked(cell) { return nil }
        }
        return cell
    }

    /// A self-avoiding walk of `count` cards from the start, inside the grid.
    static func walk(_ world: GridWorld, count: Int, rng: inout SeededRandom) -> [GridMove] {
        for _ in 0..<200 {
            var cell = world.start
            var seen: Set<GridPoint> = [cell]
            var cards: [GridMove] = []
            while cards.count < count {
                let options = GridMove.allCases.filter {
                    let next = world.next(from: cell, $0)
                    return !world.isBlocked(next) && !seen.contains(next)
                }
                if options.isEmpty { break }
                let move = options[rng.below(options.count)]
                cell = world.next(from: cell, move)
                seen.insert(cell)
                cards.append(move)
            }
            if cards.count == count { return cards }
        }
        return Array(repeating: .right, count: count)
    }

    static func cells(_ world: GridWorld, _ cards: [GridMove]) -> [GridPoint] {
        var cell = world.start
        var out = [cell]
        for card in cards {
            cell = world.next(from: cell, card)
            out.append(cell)
        }
        return out
    }
}

/// C1: pre-laid arrow cards on a 3x3 or 4x4 grid.
public struct RobotC1Presentation: Equatable, Sendable {
    public let world: GridWorld
    public let cards: [GridMove]

    public init(world: GridWorld, cards: [GridMove]) {
        self.world = world
        self.cards = cards
    }

    public var endCell: GridPoint { RobotRoute.end(world, cards) ?? world.start }

    public static func make(seed: UInt64) -> RobotC1Presentation {
        var rng = SeededRandom(seed: seed ^ 0xC1C1)
        let side = 3 + rng.below(2)
        let count = 2 + rng.below(3)
        let probe = GridWorld(width: side, height: side, start: GridPoint(0, 0), goal: GridPoint(side - 1, side - 1))
        let cards = RobotRoute.walk(probe, count: count, rng: &rng)
        let end = RobotRoute.end(probe, cards) ?? probe.start
        return RobotC1Presentation(
            world: GridWorld(width: side, height: side, start: probe.start, goal: end), cards: cards)
    }
}

/// C2: empty slots filled from a four-arrow palette on a grid with rocks.
public struct RobotC2Presentation: Equatable, Sendable {
    public let world: GridWorld
    public let slotCount: Int
    public let palette: [GridMove]
    public let referenceRoute: [GridMove]

    public static func make(seed: UInt64) -> RobotC2Presentation {
        var rng = SeededRandom(seed: seed ^ 0xC2C2)
        let side = 3 + rng.below(3)
        let count = 2 + rng.below(4)
        let open = GridWorld(width: side, height: side, start: GridPoint(0, 0), goal: GridPoint(0, 0))
        let route = RobotRoute.walk(open, count: count, rng: &rng)
        let cells = RobotRoute.cells(open, route)
        var world = GridWorld(width: side, height: side, start: open.start, goal: cells[cells.count - 1])
        let free = (0..<side * side).map { GridPoint($0 % side, $0 / side) }.filter { !cells.contains($0) }
        let rockCount = min(free.count, 1 + rng.below(2))
        for point in rng.shuffled(free).prefix(rockCount) { world.addRock(point) }
        return RobotC2Presentation(world: world, slotCount: count, palette: GridMove.allCases,
                                   referenceRoute: route)
    }
}

/// C3: a program with exactly one wrong card to find and swap.
public struct RobotC3Presentation: Equatable, Sendable {
    public let world: GridWorld
    public let cards: [GridMove]
    public let fixedCards: [GridMove]
    public var discrepancyCount: Int { cards.indices.filter { cards[$0] != fixedCards[$0] }.count }

    public static func make(seed: UInt64) -> RobotC3Presentation {
        var rng = SeededRandom(seed: seed ^ 0xC3C3)
        let side = 3 + rng.below(2)
        let count = 3 + rng.below(3)
        let open = GridWorld(width: side, height: side, start: GridPoint(0, 0), goal: GridPoint(0, 0))
        let fixed = RobotRoute.walk(open, count: count, rng: &rng)
        let goal = RobotRoute.cells(open, fixed).last ?? open.start
        let world = GridWorld(width: side, height: side, start: open.start, goal: goal)
        let index = rng.below(count)
        let others = GridMove.allCases.filter { $0 != fixed[index] }
        var buggy = fixed
        buggy[index] = others[rng.below(others.count)]
        return RobotC3Presentation(world: world, cards: buggy, fixedCards: fixed)
    }
}
