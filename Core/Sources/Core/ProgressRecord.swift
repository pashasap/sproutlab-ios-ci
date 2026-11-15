import Foundation

public struct ProgressRecord: Equatable, Codable, Sendable {
    public static let currentVersion = 4
    public static let starsPerRound = 3

    public var schemaVersion = ProgressRecord.currentVersion
    public var settings = SettingsSection()
    public var stars = StarsSection()
    public var levels: [String: LevelProgress] = [:]
    public var sessionCount = 0
    public var collection = CollectionSection()
    public var creations = CreationsSection()
    public var stamps: [String: ResidentStamps] = [:]

    public init() {}

    /// Marks one stamp for a resident. Idempotent; touches nothing else.
    public mutating func recordStamp(_ stamp: Stamp, for id: String) {
        stamps[id, default: ResidentStamps()].set(stamp)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Sections default on decode, so a decoded record is always in the current shape.
        schemaVersion = ProgressRecord.currentVersion
        settings = try c.decodeIfPresent(SettingsSection.self, forKey: .settings) ?? SettingsSection()
        stars = try c.decodeIfPresent(StarsSection.self, forKey: .stars) ?? StarsSection()
        levels = try c.decodeIfPresent([String: LevelProgress].self, forKey: .levels) ?? [:]
        sessionCount = try c.decodeIfPresent(Int.self, forKey: .sessionCount) ?? 0
        collection = try c.decodeIfPresent(CollectionSection.self, forKey: .collection) ?? CollectionSection()
        creations = try c.decodeIfPresent(CreationsSection.self, forKey: .creations) ?? CreationsSection()
        stamps = try c.decodeIfPresent([String: ResidentStamps].self, forKey: .stamps) ?? [:]
    }

    public static func fresh() -> ProgressRecord { ProgressRecord() }

    public static let defaults = ProgressRecord.fresh()

    // MARK: convenience accessors (flat view over the sections)

    public var language: Language {
        get { settings.language }
        set { settings.language = newValue }
    }

    public var musicOn: Bool {
        get { settings.music }
        set { settings.music = newValue }
    }

    public var totalStars: Int {
        get { stars.total }
        set { stars.total = newValue }
    }

    /// Ids with completions >= 1, sorted. Setting it marks listed ids completed and clears the others.
    public var completedLevels: [String] {
        get { levels.filter { $0.value.completions >= 1 }.keys.sorted() }
        set {
            for id in levels.keys where !newValue.contains(id) { levels[id]?.completions = 0 }
            for id in newValue where (levels[id]?.completions ?? 0) < 1 {
                levels[id, default: LevelProgress()].completions = 1
            }
        }
    }

    /// Reward commit: adds stars and counts one more completion of the level. Stars <= 0 change nothing.
    public func completing(levelId: String, stars: Int) -> ProgressRecord {
        guard stars > 0 else { return self }
        var copy = self
        copy.stars.total += stars
        copy.levels[levelId, default: LevelProgress()].completions += 1
        return copy
    }

    /// One finished round: a fixed award, one more completion, history capped at the newest 50.
    public mutating func recordRound(_ entry: RoundEntry) {
        stars.total += ProgressRecord.starsPerRound
        var progress = levels[entry.levelId, default: LevelProgress()]
        progress.completions += 1
        if !entry.helpUsed { progress.independentCompletions += 1 }
        progress.lastSession = sessionCount
        progress.reviewStage = 0
        levels[entry.levelId] = progress
        stars.history.append(entry)
        let extra = stars.history.count - StarsSection.historyCap
        if extra > 0 { stars.history.removeFirst(extra) }
    }
}

public struct SaveReport: Equatable, Sendable {
    public var time: Date
    public var success: Bool

    public init(time: Date, success: Bool) {
        self.time = time
        self.success = success
    }
}

public enum ProgressNotice: Equatable, Sendable {
    case missingFile
    case corruptFile
    case unsupportedVersion
}

public struct ProgressLoad: Equatable, Sendable {
    public var record: ProgressRecord
    public var notice: ProgressNotice?

    public init(record: ProgressRecord, notice: ProgressNotice?) {
        self.record = record
        self.notice = notice
    }
}

public protocol ProgressStore: Sendable {
    func load() -> ProgressLoad
    func save(_ record: ProgressRecord) -> SaveReport
}
