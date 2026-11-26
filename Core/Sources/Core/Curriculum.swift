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
    public static let titleKeys = ["trail.level.math-m1-count.title", "trail.level.math-m4-tens-ones.title",
                                   "trail.level.math-m2-ten.title",
                                   "trail.level.math-bonds-10.title", "trail.level.math-add-sub-20.title",
                                   "trail.level.math-m3-bridge-ten.title",
                                   "trail.level.math-patterns-20.title"] + readingTitleKeys + readingENTitleKeys
        + robotTitleKeys + musicTitleKeys

    public static let all: [LevelDefinition] = mathLevels + readingLevels + readingENLevels + robotLevels
        + musicLevels

    static let mathLevels: [LevelDefinition] = [
        LevelDefinition(
            levelId: "math-m1-count",
            strand: "math",
            titleKey: "trail.level.math-m1-count.title",
            activity: LevelActivity(
                type: "count-objects",
                generator: { M1Generator.items(seed: $0) },
                helpSteps: ["m1.help.mark", "m1.help.row", "m1.help.demo"],
                prerequisites: []
            ).enumerating { M1Generator.allConfigurations() }
        ).coded("M1"),
        LevelDefinition(
            levelId: "math-m4-tens-ones",
            strand: "math",
            titleKey: "trail.level.math-m4-tens-ones.title",
            activity: LevelActivity(
                type: "tens-ones",
                generator: { M4Generator.items(seed: $0) },
                helpSteps: ["m4.help.trays", "m4.help.values", "m4.help.digit"],
                prerequisites: ["math-m1-count"]
            ).enumerating { M4Generator.allConfigurations() }
        ).coded("M4"),
        LevelDefinition(
            levelId: "math-m2-ten",
            strand: "math",
            titleKey: "trail.level.math-m2-ten.title",
            activity: LevelActivity(
                type: "compose-ten",
                generator: { M2Generator.items(seed: $0) },
                helpSteps: ["m2.help.whole", "m2.help.spaces", "m2.help.move"],
                prerequisites: ["math-m1-count"]
            ).enumerating { M2Generator.allConfigurations() }
        ).coded("M2"),
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
            levelId: "math-m3-bridge-ten",
            strand: "math",
            titleKey: "trail.level.math-m3-bridge-ten.title",
            activity: LevelActivity(
                type: "bridge-ten",
                generator: { M3Generator.items(seed: $0) },
                helpSteps: ["m3.help.frames", "m3.help.ten", "m3.help.first"],
                prerequisites: ["math-add-sub-20"]
            ).enumerating { M3Generator.allConfigurations() }
        ).coded("M3"),
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
