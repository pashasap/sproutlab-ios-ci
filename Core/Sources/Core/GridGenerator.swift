import Foundation

public enum GridGenerator {
    /// Breadth-first shortest route from start to goal, or nil when none exists.
    public static func route(in world: GridWorld) -> [GridMove]? {
        var parents: [GridPoint: (GridPoint, GridMove)] = [:]
        var seen: Set<GridPoint> = [world.start]
        var queue = [world.start]
        var head = 0
        while head < queue.count {
            let cell = queue[head]
            head += 1
            if cell == world.goal { return path(to: cell, parents: parents) }
            for move in GridMove.allCases {
                let next = world.next(from: cell, move)
                if world.isBlocked(next) || !seen.insert(next).inserted { continue }
                parents[next] = (cell, move)
                queue.append(next)
            }
        }
        return nil
    }

    private static func path(to goal: GridPoint, parents: [GridPoint: (GridPoint, GridMove)]) -> [GridMove] {
        var moves: [GridMove] = []
        var cell = goal
        while let (previous, move) = parents[cell] {
            moves.append(move)
            cell = previous
        }
        return moves.reversed()
    }

    static func pick(_ rng: inout SeededRandom, _ count: Int) -> Int {
        Int(rng.next() % UInt64(max(count, 1)))
    }

    /// Every returned world is solvable: a rock is only kept when a route still exists.
    public static func generate(seed: UInt64) -> GridWorld {
        var rng = SeededRandom(seed: seed)
        let width = 4 + pick(&rng, 2)
        let height = 4 + pick(&rng, 2)
        var world = GridWorld(width: width, height: height, start: GridPoint(0, 0),
                              goal: GridPoint(width - 1, height - 1))
        for _ in 0..<(width * height / 4) {
            let cell = GridPoint(pick(&rng, width), pick(&rng, height))
            if cell == world.start || cell == world.goal { continue }
            var trial = world
            trial.addRock(cell)
            if route(in: trial) != nil { world = trial }
        }
        decorate(&world, rng: &rng)
        return world
    }

    private static func decorate(_ world: inout GridWorld, rng: inout SeededRandom) {
        for _ in 0..<3 {
            let cell = GridPoint(pick(&rng, world.width), pick(&rng, world.height))
            if cell == world.start || cell == world.goal || world.rocks.contains(cell) { continue }
            if pick(&rng, 2) == 0 { world.addPuddle(cell) } else { world.addItem(cell) }
        }
    }
}

public struct GridDebugItem: Sendable {
    public let world: GridWorld
    public let fixedProgram: [GridMove]
    public let buggyProgram: [GridMove]

    /// Builds a solvable item whose buggy program differs from the fixed one at exactly one card.
    public static func make(seed: UInt64) -> GridDebugItem {
        let world = GridGenerator.generate(seed: seed)
        let fixed = GridGenerator.route(in: world) ?? []
        var rng = SeededRandom(seed: seed ^ 0x9E37_79B9_7F4A_7C15)
        var buggy = fixed
        if !fixed.isEmpty {
            let index = GridGenerator.pick(&rng, fixed.count)
            let others = GridMove.allCases.filter { $0 != fixed[index] }
            buggy[index] = others[GridGenerator.pick(&rng, others.count)]
        }
        return GridDebugItem(world: world, fixedProgram: fixed, buggyProgram: buggy)
    }
}
