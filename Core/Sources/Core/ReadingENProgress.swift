import Foundation

/// Progress of the readingEN track (schema 5). It is stored apart from the shared level table, so the
/// English and French reading histories never merge, whichever language the app shows.
public struct ReadingENProgress: Equatable, Codable, Sendable {
    public var stars: Int = 0
    public var levels: [String: LevelProgress] = [:]
    public var history: [RoundEntry] = []
    public var isEmpty: Bool { stars == 0 && levels.isEmpty && history.isEmpty }

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stars = try c.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        levels = try c.decodeIfPresent([String: LevelProgress].self, forKey: .levels) ?? [:]
        history = try c.decodeIfPresent([RoundEntry].self, forKey: .history) ?? []
    }
}

extension ProgressRecord {
    /// Progress of one level, read from the track that owns it.
    public func progress(for levelId: String) -> LevelProgress? {
        ReadingENBank.owns(levelId: levelId) ? readingEN.levels[levelId] : levels[levelId]
    }

    /// Stores the progress of one level in the track that owns it.
    public mutating func setProgress(_ progress: LevelProgress, for levelId: String) {
        if ReadingENBank.owns(levelId: levelId) {
            readingEN.levels[levelId] = progress
        } else {
            levels[levelId] = progress
        }
    }

    /// One finished readingEN round: stars and history stay inside the readingEN section.
    mutating func recordReadingENRound(_ entry: RoundEntry) {
        readingEN.stars += ProgressRecord.starsPerRound
        var progress = readingEN.levels[entry.levelId, default: LevelProgress()]
        progress.completions += 1
        if !entry.helpUsed { progress.independentCompletions += 1 }
        progress.lastSession = sessionCount
        progress.reviewStage = 0
        readingEN.levels[entry.levelId] = progress
        readingEN.history.append(entry)
        let extra = readingEN.history.count - StarsSection.historyCap
        if extra > 0 { readingEN.history.removeFirst(extra) }
    }
}
