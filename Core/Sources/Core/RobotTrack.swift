import Foundation

/// A lane of the trail described as data: an id, a name key and the level ids in lane order.
public struct TrackDefinition: Equatable, Sendable {
    public let id: String
    public let nameKey: String
    public let levelIds: [String]

    public func name(_ language: Language) -> String { TextTable.string(nameKey, language) }
}

public enum TrackCatalog {
    public struct Catalog: Sendable {
        public let tracks: [TrackDefinition]
    }

    public static let standard = Catalog(tracks: [
        ("math", "lane.math.title"), ("readingFR", "icon.readingFR.label"),
        ("readingEN", "icon.readingEN.label"), ("robot", "track.robot.name")
    ].map { id, key in
        TrackDefinition(id: id, nameKey: key,
                        levelIds: LevelCatalog.standard.levels.filter { $0.track == id }.map(\.levelId))
    })
}

/// Touch targets of the robot levels, in points.
public enum RobotLayout {
    public static let slotSide = 64.0
    public static let paletteSide = 64.0
    public static let repeatDotSide = 60.0
}

/// Child-path text of the robot track: short imperatives, no speech, no failure words.
public enum RobotText {
    public static let arrowSymbols: [GridMove: String] = [
        .up: "arrow.up", .down: "arrow.down", .left: "arrow.left", .right: "arrow.right"
    ]
    public static let markerSymbol = "ant.fill"
    public static let robotSymbol = "gearshape.fill"
    public static let rockSymbol = "square.grid.3x3.fill"
    public static let goalSymbol = "star.fill"
    public static let emptyCellSymbol = "circle"
    public static let stepSymbol = "forward.frame.fill"
    public static let playSymbol = "play.fill"
    public static let emptySlotSymbol = "square.dashed"
    public static let fallbackArrow = "arrow.right"

    public static func arrow(_ move: GridMove) -> String { arrowSymbols[move] ?? fallbackArrow }

    public static func cellLabel(_ point: GridPoint) -> String { "\(point.x + 1),\(point.y + 1)" }

    static let keys = ["robot.tap.step", "robot.choose.cell", "robot.look.robot", "robot.try.again",
                       "robot.change.card", "robot.tap.play", "robot.choose.arrow"]

    public static func childStrings(_ language: Language) -> [String] {
        keys.map { TextTable.string($0, language) }
    }

    public static func allowedImperatives(_ language: Language) -> Set<String> {
        language == .fr ? ["Appuie", "Choisis", "Regarde", "Essaie", "Change"]
                        : ["Tap", "Choose", "Look", "Try", "Change"]
    }

    /// The robot has no voice: it only beeps and moves.
    public static func speechLines(_ language: Language) -> [String] { [] }

    public static func label(_ move: GridMove, _ language: Language) -> String {
        TextTable.string("robot.arrow.\(move.rawValue)", language)
    }
}

extension TextTable {
    static let robotTexts: [String: TextEntry] = [
        "track.robot.name": TextEntry("Petit Robot", "Little Robot"),
        "trail.level.robot-c1.title": TextEntry("Pas à pas", "Step by step"),
        "trail.level.robot-c2.title": TextEntry("Remplis les cases", "Fill the slots"),
        "trail.level.robot-c3.title": TextEntry("Trouve la fourmi", "Find the ant"),
        "trail.level.robot-c4.title": TextEntry("Plus court, répète", "Say it shorter, repeat"),
        "robot.tap.step": TextEntry("Appuie ici", "Tap here"),
        "robot.choose.cell": TextEntry("Choisis la case", "Choose the cell"),
        "robot.look.robot": TextEntry("Regarde le robot", "Look at it"),
        "robot.try.again": TextEntry("Essaie encore", "Try again"),
        "robot.change.card": TextEntry("Change la carte", "Change the card"),
        "robot.tap.play": TextEntry("Appuie sur jouer", "Tap play"),
        "robot.choose.arrow": TextEntry("Choisis une flèche", "Choose an arrow"),
        "robot.arrow.up": TextEntry("Flèche haut", "Up arrow"),
        "robot.arrow.down": TextEntry("Flèche bas", "Down arrow"),
        "robot.arrow.left": TextEntry("Flèche gauche", "Left arrow"),
        "robot.arrow.right": TextEntry("Flèche droite", "Right arrow"),
        "robot.step": TextEntry("Un pas", "One step"),
        "robot.play": TextEntry("Jouer", "Play"),
        "robot.undo": TextEntry("Enlever", "Remove"),
        "robot.ant": TextEntry("Fourmi", "Ant"),
        "robot.marker": TextEntry("Fourmi", "Ant")
    ]
}

/// Items of the robot levels: one per round position, tagged with the level they belong to.
enum RobotItems {
    static func items(code: String, seed: UInt64) -> [Item] {
        var rng = SeededRandom(seed: seed ^ 0x0B07)
        return (1...5).map { position in
            var item = Item(kind: .counting, operand: 1, choices: [1, 2, 3], correctIndex: 0)
            item.robotId = "robot.\(code)"
            item.iconKey = "icon.robot"
            item.configuration = 5000 + rng.below(1000)
            return item.placed(at: position, of: 5)
        }
    }

    static func configurations(code: String) -> [Item] {
        (0..<5).map { index in
            var item = Item(kind: .counting, operand: 1, choices: [1, 2, 3], correctIndex: 0)
            item.robotId = "robot.\(code)"
            item.iconKey = "icon.robot"
            item.configuration = 5000 + index
            return item.placed(at: 2, of: 5)
        }
    }
}

extension Curriculum {
    private static func robotLevel(_ code: String, after: String?) -> LevelDefinition {
        let id = "robot-\(code.lowercased())"
        return LevelDefinition(
            levelId: id, strand: "robot", titleKey: "trail.level.\(id).title",
            activity: LevelActivity(
                type: id, generator: { RobotItems.items(code: code, seed: $0) },
                helpSteps: ["round.help.step", "round.help.compare"], prerequisites: after.map { [$0] } ?? []
            ).enumerating { RobotItems.configurations(code: code) }
        ).coded(code)
    }

    static let robotLevels: [LevelDefinition] = [
        robotLevel("C1", after: nil), robotLevel("C2", after: "robot-c1"), robotLevel("C3", after: "robot-c2"),
        robotLevel("C4", after: "robot-c3")
    ]

    static let robotTitleKeys = ["robot-c1", "robot-c2", "robot-c3", "robot-c4"].map { "trail.level.\($0).title" }
}
