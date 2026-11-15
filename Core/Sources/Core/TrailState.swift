public enum TrailState: Equatable, Sendable {
    case locked(requires: String)
    case open
    case suggested
    case completed
    case dueForReview
}

public struct TrailTile: Equatable, Sendable {
    public let levelId: String
    public let code: String
    public let title: String
    public let state: TrailState
    public let identities: [ActivityIdentity]
    public let presentation: TrailTilePresentation
}

public struct TrailLane: Equatable, Sendable {
    public let track: String
    public let tiles: [TrailTile]
}

/// When a level is ready to suggest its successor.
public enum MasteryPolicy {
    public static let independentNeeded = 6
    public static let visitsNeeded = 2
    public static let unfamiliarNeeded = 2

    public static func suggestsNext(level: String, record: ProgressRecord) -> Bool {
        guard let p = record.levels[level] else { return false }
        return p.independentCompletions >= independentNeeded
            && p.visits >= visitsNeeded
            && p.unfamiliarSeen >= unfamiliarNeeded
    }
}

/// Spaced review of completed levels: stages after about 1, 3 and 7 sessions.
public enum ReviewScheduler {
    public static let intervals = [1, 3, 7]

    /// The session from which the level is due again; nil once every stage has been reviewed.
    public static func nextReviewSession(for progress: LevelProgress) -> Int? {
        guard progress.reviewStage >= 0, progress.reviewStage < intervals.count else { return nil }
        return progress.lastSession + intervals[progress.reviewStage]
    }

    public static func isDue(_ levelId: String, record: ProgressRecord) -> Bool {
        guard let p = record.levels[levelId], p.completions >= 1,
              let next = nextReviewSession(for: p) else { return false }
        return next <= record.sessionCount
    }

    /// Moves a reviewed level to its next stage; it never changes completion.
    static func advance(_ levelId: String, in record: inout ProgressRecord) {
        guard isDue(levelId, record: record) else { return }
        record.levels[levelId]?.reviewStage += 1
    }
}
