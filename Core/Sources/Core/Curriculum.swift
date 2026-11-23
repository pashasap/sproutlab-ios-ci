/// The activity part of a level: what it plays and how it helps.
public struct LevelActivity: Sendable {
    public let activityType: String
    public let generator: @Sendable (UInt64) -> [Item]
    /// Text keys, one per help step.
    public let helpSteps: [String]
    public let prerequisites: [String]
    /// Finite domain for exhaustive content linting, registered alongside the generator.
    public var configurations: (@Sendable () -> [Item])?

    public func enumerating(_ configurations: @escaping @Sendable () -> [Item]) -> LevelActivity {
        var copy = self
        copy.configurations = configurations
        return copy
    }

    public init(type: String, generator: @escaping @Sendable (UInt64) -> [Item],
                helpSteps: [String], prerequisites: [String]) {
        self.activityType = type
        self.generator = generator
        self.helpSteps = helpSteps
        self.prerequisites = prerequisites
    }
}

public struct LevelDefinition: Sendable {
    public let levelId: String
    public let strand: String
    public let titleFR: String
    public let titleEN: String
    public let activityType: String
    public let generator: @Sendable (UInt64) -> [Item]
    public let helpSteps: [String]
    public let prerequisites: [String]
    public let iconKey: String
    public let colourName: String
    public let titleKey: String
    public let configurations: (@Sendable () -> [Item])?
    /// Curriculum code such as "M3"; empty for a level added without one.
    public var code: String = ""
    /// A reach level is optional stretch content and never blocks the next level.
    public var isReach: Bool = false

    /// The lane this level sits in; equal to its strand.
    public var track: String { strand }

    public func coded(_ code: String, reach: Bool = false) -> LevelDefinition {
        var copy = self
        copy.code = code
        copy.isReach = reach
        return copy
    }

    public init(levelId: String, strand: String, titleKey: String, activity: LevelActivity) {
        self.titleKey = titleKey
        self.configurations = activity.configurations
        self.iconKey = "icon." + strand
        self.colourName = "colour." + strand
        self.levelId = levelId
        self.strand = strand
        self.titleFR = TextTable.string(titleKey, .fr)
        self.titleEN = TextTable.string(titleKey, .en)
        self.activityType = activity.activityType
        self.generator = activity.generator
        self.helpSteps = activity.helpSteps
        self.prerequisites = activity.prerequisites
    }
}

public enum Curriculum {
    public static let titleKeys = ["trail.level.math-bonds-10.title", "trail.level.math-add-sub-20.title",
                                   "trail.level.math-patterns-20.title"] + readingTitleKeys + readingENTitleKeys
        + robotTitleKeys

    public static let all: [LevelDefinition] = mathLevels + readingLevels + readingENLevels + robotLevels

    static let mathLevels: [LevelDefinition] = [
        LevelDefinition(
            levelId: "math-bonds-10",
            strand: "math",
            titleKey: "trail.level.math-bonds-10.title",
            activity: LevelActivity(
                type: "counting-and-bonds",
                generator: { CountingBondsGenerator.items(seed: $0) },
                helpSteps: ["round.help.groups", "round.help.count"],
                prerequisites: []
            ).enumerating { CountingBondsGenerator.allConfigurations() }
        ).coded("M3"),
        LevelDefinition(
            levelId: "math-add-sub-20",
            strand: "math",
            titleKey: "trail.level.math-add-sub-20.title",
            activity: LevelActivity(
                type: "add-and-subtract",
                generator: { AddSubGenerator.items(seed: $0) },
                helpSteps: ["round.help.join", "round.help.crossed"],
                prerequisites: ["math-bonds-10"]
            ).enumerating { AddSubGenerator.allConfigurations() }
        ).coded("M4"),
        LevelDefinition(
            levelId: "math-patterns-20",
            strand: "math",
            titleKey: "trail.level.math-patterns-20.title",
            activity: LevelActivity(
                type: "patterns-and-comparison",
                generator: { PatternsGenerator.items(seed: $0) },
                helpSteps: ["round.help.step", "round.help.compare"],
                prerequisites: ["math-add-sub-20"]
            ).enumerating { PatternsGenerator.allConfigurations() }
        ).coded("M5")
    ]
}
