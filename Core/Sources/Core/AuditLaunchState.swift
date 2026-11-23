import Foundation

/// The initial app state `-auditStop` opens: the screen, the exact level, seed and question,
/// and the seeded record the app uses instead of any saved progress. Pure and deterministic.
public struct AuditLaunchState: Equatable, Sendable {
    public let stopId: String
    /// The stop's root identifier; only the rendered screen or sheet of this stop carries it.
    public let rootId: String
    public let screen: AuditScreen
    /// Empty when the stop opens no level.
    public let levelId: String
    public let seed: UInt64
    public let questionIndex: Int
    /// 3 on the round-summary stop, 0 elsewhere.
    public let earnedStars: Int
    public let animationsEnabled: Bool
    public let ignoresSavedProgress: Bool
    /// The seeded record: the stop's level (or the resident collection) is unlocked.
    public let record: ProgressRecord

    public init(launch: AuditLaunch) {
        stopId = launch.stopId
        rootId = launch.root
        screen = launch.state.screen
        levelId = launch.state.levelId
        seed = launch.state.seed
        questionIndex = launch.state.questionIndex
        earnedStars = launch.state.screen == .summary ? ProgressRecord.starsPerRound : 0
        animationsEnabled = launch.animationsEnabled
        ignoresSavedProgress = true
        record = Self.seededRecord(screen: launch.state.screen, levelId: launch.state.levelId)
    }

    private static func seededRecord(screen: AuditScreen, levelId: String) -> ProgressRecord {
        var record = ProgressRecord.fresh()
        // Complete every other level so the target level is unlocked whatever its place in its lane.
        let others = LevelCatalog.standard.levels.map(\.levelId).filter { $0 != levelId }
        if !levelId.isEmpty || screen == .trail { record.completedLevels = others }
        if screen == .journal || screen == .terrarium || screen == .gallery {
            record.collection.welcomed = Collectible.table.map {
                WelcomeEntry(id: $0.id, date: Date(timeIntervalSince1970: 0))
            }
        }
        return record
    }
}
