import Foundation
import Observation

public struct TrailRow: Equatable, Sendable {
    public let levelId: String
    public let title: String
    public let isCompleted: Bool
    public let isUnlocked: Bool
    /// Text-table icon key: a check mark once completed, otherwise the strand icon.
    public let iconKey: String
    public let colourName: String
    /// Check icon shown on the tile; non-nil only for a completed level.
    public let checkIcon: ChromeIcon?
}

@MainActor
@Observable
public final class TrailViewModel {
    public private(set) var record: ProgressRecord
    public private(set) var language: Language
    private let catalog: LevelCatalog
    private let services: Services?
    private var lastItems: [String: [Item]] = [:]

    public convenience init(catalog: LevelCatalog, record: ProgressRecord, language: Language,
                            services: Services) {
        self.init(catalog: catalog, record: record, language: language, optionalServices: services)
    }

    /// Read-only trail without a round source (no round can be started).
    public convenience init(curriculum: [LevelDefinition], completed: [String], language: Language) {
        var record = ProgressRecord.fresh()
        record.completedLevels = completed
        self.init(catalog: LevelCatalog(levels: curriculum), record: record, language: language,
                  optionalServices: nil)
    }

    private init(catalog: LevelCatalog, record: ProgressRecord, language: Language,
                 optionalServices: Services?) {
        self.catalog = catalog
        self.record = record
        self.language = language
        self.services = optionalServices
    }

    public func update(record: ProgressRecord, language: Language) {
        self.record = record
        self.language = language
    }

    // MARK: lanes

    public func lanes() -> [TrailLane] {
        catalog.tracks().map { entry in
            let tiles = entry.levels.indices.map { tile(entry.levels, at: $0) }
            return TrailLane(track: entry.track, tiles: tiles)
        }
    }

    public var rows: [TrailRow] {
        let levels = Dictionary(uniqueKeysWithValues: catalog.levels.map { ($0.levelId, $0) })
        return lanes().flatMap(\.tiles).compactMap { tile in
            levels[tile.levelId].map { row(for: $0, tile: tile) }
        }
    }

    private func row(for level: LevelDefinition, tile: TrailTile) -> TrailRow {
        var done = false
        var unlocked = true
        switch tile.state {
        case .completed, .dueForReview: done = true
        case .locked: unlocked = false
        case .open, .suggested: break
        }
        return TrailRow(
            levelId: level.levelId, title: tile.title, isCompleted: done, isUnlocked: unlocked,
            iconKey: done ? "icon.completed" : level.iconKey, colourName: level.colourName,
            checkIcon: done ? ChromeCatalog.icon(.check, language: language) : nil)
    }

    private func tile(_ lane: [LevelDefinition], at index: Int) -> TrailTile {
        let level = lane[index]
        let state = state(lane, at: index)
        return TrailTile(levelId: level.levelId, code: level.code,
                         title: language == .fr ? level.titleFR : level.titleEN,
                         state: state, identities: level.activityIdentities,
                         presentation: TrailTilePresentation(level: level, state: state, language: language))
    }

    private func state(_ lane: [LevelDefinition], at index: Int) -> TrailState {
        TrailState.resolve(level: lane[index], previous: index > 0 ? lane[index - 1].levelId : nil,
                           record: record)
    }

    // MARK: rounds

    /// Starts a round of an open, suggested or completed level; nil (nothing changed) when locked or unknown.
    public func startRound(levelId: String) -> RoundViewModel? {
        guard let services, let lane = catalog.lane(containing: levelId),
              let index = lane.firstIndex(where: { $0.levelId == levelId }) else { return nil }
        if case .locked = state(lane, at: index) { return nil }
        let input = PlanInput(level: lane[index], earlier: Array(lane[..<index]), record: record,
                              previous: lastItems[levelId])
        let plan = RoundPlanner.plan(input, seeds: { services.nextSeed() })
        lastItems[levelId] = plan.items
        let model = RoundViewModel(round: Round(levelId: levelId, seed: plan.seed, items: plan.items),
                                   language: language, haptics: services.haptics)
        model.reviewedLevelId = plan.reviewedLevelId
        return model
    }

    /// Commits a finished round once: stars, completion, visit, review and configurations.
    public func commit(_ round: RoundViewModel) {
        guard round.summary != nil, !round.isCommitted else { return }
        round.isCommitted = true
        var progress = record.levels[round.levelId] ?? LevelProgress()
        let configurations = Set(round.items.map(\.configuration))
        if progress.visits == 0 || progress.lastSession != record.sessionCount { progress.visits += 1 }
        progress.unfamiliarSeen += configurations.subtracting(progress.configurationsSeen).count
        progress.configurationsSeen = configurations.union(progress.configurationsSeen).sorted()
        record.levels[round.levelId] = progress
        let correct = max(0, round.questionCount - round.wrongAttempts)
        record.recordRound(RoundEntry(levelId: round.levelId, date: Date(), firstTryCount: correct,
                                      helpUsed: round.sawWrongAnswer))
        if let reviewed = round.reviewedLevelId { ReviewScheduler.advance(reviewed, in: &record) }
    }
}
