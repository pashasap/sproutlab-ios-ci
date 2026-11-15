import Foundation

/// Pure state of a collectible, derived from the saved record alone. Never mutates anything.
public enum CollectionEvaluator {
    public static func state(for item: Collectible, record: ProgressRecord) -> CollectibleState {
        if isWelcomed(item.id, in: record) { return .met }
        return state(rule: item.rule, record: record)
    }

    /// Rule only: `.notArrived` or `.ready`.
    public static func state(rule: UnlockRule, record: ProgressRecord) -> CollectibleState {
        satisfied(rule, record) ? .ready : .notArrived
    }

    static func isWelcomed(_ id: String, in record: ProgressRecord) -> Bool {
        record.collection.welcomed.contains { $0.id == id }
    }

    private static func satisfied(_ rule: UnlockRule, _ record: ProgressRecord) -> Bool {
        switch rule {
        case .free:
            return true
        case .stars(let n):
            return record.stars.total >= n
        case .firstCompletion(let levelId, let fallback):
            return (record.levels[levelId]?.completions ?? 0) >= 1 || record.stars.total >= fallback
        case .arrivesWithHabitat(let id):
            return isWelcomed(id, in: record)
        case .lifeStage(let id, _):
            return isWelcomed(id, in: record)
        }
    }
}
