/// The screens an audit stop can open.
public enum AuditScreen: String, Equatable, Sendable {
    case welcome, trail, round, summary, terrarium, gallery, journal, diagnostics
}

/// The app state a stop opens: a screen and, for a question stop, the level, the question and the fixed seed.
public struct AuditStopState: Equatable, Sendable {
    public let screen: AuditScreen
    /// Empty for a stop that opens no level.
    public let levelId: String
    public let questionIndex: Int
    public let seed: UInt64

    /// The state of the stop `id`; nil for an unknown id. The same id always gives the same value.
    public static func state(forStop id: String) -> AuditStopState? {
        table[id]
    }

    /// What a question stop must show: a level and the kind of question found in it.
    private struct Target {
        let levelId: String
        let kind: String
    }

    private static let screens: [String: AuditScreen] = [
        "welcome": .welcome, "explorer-trail": .trail, "round-summary": .summary, "terrarium": .terrarium,
        "creature-gallery": .gallery, "journal": .journal, "diagnostics": .diagnostics
    ]

    private static let targets: [String: Target] = [
        "math-m1-count": Target(levelId: "math-m1-count", kind: "math.m1"),
        "math-m2-ten": Target(levelId: "math-m2-ten", kind: "math.bond"),
        "math-counting": Target(levelId: "math-bonds-10", kind: "math.counting"),
        "math-make-ten": Target(levelId: "math-bonds-10", kind: "math.bond"),
        "math-addition": Target(levelId: "math-add-sub-20", kind: "math.addition"),
        "math-subtraction": Target(levelId: "math-add-sub-20", kind: "math.subtraction"),
        "math-pattern": Target(levelId: "math-patterns-20", kind: "math.pattern"),
        "math-comparison": Target(levelId: "math-patterns-20", kind: "math.comparison"),
        "reading-tap-grapheme": Target(levelId: "reading-fr-r1", kind: "r1.tapGrapheme"),
        "reading-sequence-sounds": Target(levelId: "reading-fr-r1", kind: "r1.sequenceSounds"),
        "reading-blend-new": Target(levelId: "reading-fr-r1", kind: "r1.blendNew"),
        "reading-decode-reveal": Target(levelId: "reading-fr-r2", kind: "r2.decodeReveal"),
        "reading-change-grapheme": Target(levelId: "reading-fr-r2", kind: "r2.changeGrapheme"),
        "reading-build-word": Target(levelId: "reading-fr-r2", kind: "r2.buildWord"),
        "reading-select-digraph": Target(levelId: "reading-fr-r3", kind: "r3.selectDigraph"),
        "reading-blend-word": Target(levelId: "reading-fr-r3", kind: "r3.blendWord"),
        "reading-repair-split": Target(levelId: "reading-fr-r3", kind: "r3.repairSplit"),
        "reading-fr-r6": Target(levelId: "reading-fr-r6", kind: "frr6.sentence"),
        "reading-en-r6": Target(levelId: "reading-en-r6", kind: "enr6.sentence"),
        "reading-en-sounds": Target(levelId: "reading-en-en1", kind: "en1.graphemeSound"),
        "reading-en-words": Target(levelId: "reading-en-en2", kind: "en2.changeGrapheme"),
        "reading-en-digraphs": Target(levelId: "reading-en-en3", kind: "en3.digraph"),
        "robot-c1": Target(levelId: "robot-c1", kind: "robot.C1"),
        "robot-c2": Target(levelId: "robot-c2", kind: "robot.C2"),
        "robot-c3": Target(levelId: "robot-c3", kind: "robot.C3"),
        "robot-c4": Target(levelId: "robot-c4", kind: "robot.C4"),
        "music-a4": Target(levelId: "music-a4", kind: "music.A4")
    ]

    /// The first seed (counting up from 1) whose round holds the target kind, with the question index.
    private static let table: [String: AuditStopState] = {
        var out: [String: AuditStopState] = [:]
        for (id, screen) in screens {
            out[id] = AuditStopState(screen: screen, levelId: "", questionIndex: 0, seed: 1)
        }
        for (id, target) in targets {
            out[id] = resolve(target)
        }
        return out
    }()

    private static func resolve(_ target: Target) -> AuditStopState? {
        guard let level = LevelCatalog.standard.levels.first(where: { $0.levelId == target.levelId }) else { return nil }
        for seed in UInt64(1)...500 {
            let items = level.generator(seed)
            if let index = items.firstIndex(where: { matches($0, target) }) {
                return AuditStopState(screen: .round, levelId: level.levelId, questionIndex: index, seed: seed)
            }
        }
        return nil
    }

    /// The M1 stop shows a tap-and-count question over a scattered collection; the M2 stop shows a
    /// partly filled ten-frame; every other stop matches its kind.
    private static func matches(_ item: Item, _ target: Target) -> Bool {
        if let shown = item.m2 {
            return kind(of: item) == target.kind && shown.kind == .fillTenFrame
                && !shown.frame.filled.isEmpty && !shown.frame.empty.isEmpty
        }
        guard let shown = item.m1 else { return kind(of: item) == target.kind }
        return kind(of: item) == target.kind && shown.kind == .tapCount && shown.groups.first?.layout == .scattered
    }

    /// The kind a question belongs to: its math kind, or the reading rung and activity of its bank item.
    static func kind(of item: Item) -> String {
        if let robot = item.robotId { return robot }
        if item.m1 != nil { return "math.m1" }
        if let id = item.readingId, FrenchSentenceBank.item(id: id) != nil { return "frr6.sentence" }
        if let id = item.readingId, EnglishSentenceBank.item(id: id) != nil { return "enr6.sentence" }
        if let id = item.readingId, let english = ReadingENBank.item(id: id) {
            return "\(english.rung.rawValue).\(english.activity.rawValue)"
        }
        guard let id = item.readingId, let bank = ReadingBank.item(id: id) else { return "math.\(item.kind)" }
        if let activity = bank.r2Activity { return "r2.\(activity)" }
        if let activity = bank.r3Activity { return "r3.\(activity)" }
        return "r1.\(bank.activity)"
    }
}
