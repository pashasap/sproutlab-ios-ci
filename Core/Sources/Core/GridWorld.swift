import Foundation

/// A cell on a grid; y grows downward.
public struct GridPoint: Hashable, Sendable {
    public let x: Int
    public let y: Int

    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
}

/// Absolute moves only; there are no relative turns.
public enum GridMove: String, CaseIterable, Hashable, Sendable {
    case up, down, left, right

    public var delta: (dx: Int, dy: Int) {
        switch self {
        case .up: return (0, -1)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        }
    }
}

/// Obstacle kinds differ by shape pattern and colour token, never by colour alone.
public enum GridObstacleKind: CaseIterable, Sendable {
    case rock, puddle

    public var isBlocking: Bool { self == .rock }

    public var pattern: String {
        switch self {
        case .rock: return "crosshatch"
        case .puddle: return "ripples"
        }
    }

    public var colourToken: String {
        switch self {
        case .rock: return "stone"
        case .puddle: return "water"
        }
    }
}

public enum GridEvent: Equatable, Sendable {
    case moved(GridPoint)
    case blocked
    case collected(GridPoint)
    case finished
}

public struct GridWorld: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let start: GridPoint
    public let goal: GridPoint
    public private(set) var rocks: Set<GridPoint> = []
    public private(set) var puddles: Set<GridPoint> = []
    public private(set) var items: Set<GridPoint> = []

    public init(width: Int, height: Int, start: GridPoint, goal: GridPoint) {
        self.width = width
        self.height = height
        self.start = start
        self.goal = goal
    }

    public mutating func addRock(_ point: GridPoint) { rocks.insert(point) }
    public mutating func addPuddle(_ point: GridPoint) { puddles.insert(point) }
    public mutating func addItem(_ point: GridPoint) { items.insert(point) }

    public func contains(_ point: GridPoint) -> Bool {
        point.x >= 0 && point.y >= 0 && point.x < width && point.y < height
    }

    public func next(from point: GridPoint, _ move: GridMove) -> GridPoint {
        GridPoint(point.x + move.delta.dx, point.y + move.delta.dy)
    }

    public func isBlocked(_ point: GridPoint) -> Bool {
        !contains(point) || rocks.contains(point)
    }
}
