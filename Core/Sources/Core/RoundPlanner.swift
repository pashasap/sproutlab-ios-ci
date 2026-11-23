/// What a planned round plays: its seed, its items and the older level it borrows one item from.
struct RoundPlan {
    let seed: UInt64
    let items: [Item]
    let reviewedLevelId: String?
}

struct PlanInput {
    let level: LevelDefinition
    /// Levels before this one in the same lane, in order.
    let earlier: [LevelDefinition]
    let record: ProgressRecord
    /// The items of the previous round of this level, when known.
    let previous: [Item]?
}

/// Chooses a round's items: a fresh generator run, plus replay and old-friend rules.
@MainActor
enum RoundPlanner {
    static let replayTries = 12

    static func plan(_ input: PlanInput, seeds: () -> UInt64) -> RoundPlan {
        let progress = input.record.progress(for: input.level.levelId)
        let replay = (progress?.completions ?? 0) >= 1
        var seed = seeds()
        var items = input.level.generator(seed)
        if replay {
            let seen = Set(progress?.configurationsSeen ?? [])
            var tries = 1
            while tries < replayTries, !items.contains(where: { !seen.contains($0.configuration) }) {
                seed = seeds()
                items = input.level.generator(seed)
                tries += 1
            }
            items = reordered(items, against: input.previous, seed: seed)
        }
        guard let due = input.earlier.first(where: { ReviewScheduler.isDue($0.levelId, record: input.record) }),
              let mixed = withOldFriend(items, from: due, seed: seed) else {
            return RoundPlan(seed: seed, items: items, reviewedLevelId: nil)
        }
        return RoundPlan(seed: seed, items: mixed, reviewedLevelId: due.levelId)
    }

    /// Replaces one item by an item of an older level.
    static func withOldFriend(_ items: [Item], from old: LevelDefinition, seed: UInt64) -> [Item]? {
        let pool = old.generator(seed &+ 1)
        guard !pool.isEmpty, !items.isEmpty else { return nil }
        var rng = SeededRandom(seed: seed &+ 7)
        var out = items
        out[rng.below(items.count)] = pool[rng.below(pool.count)]
        return out
    }

    /// Items that repeat the previous round's question keep their question but get a new choice order.
    static func reordered(_ items: [Item], against previous: [Item]?, seed: UInt64) -> [Item] {
        guard let previous else { return items }
        var rng = SeededRandom(seed: seed &+ 13)
        return items.enumerated().map { index, item in
            guard index < previous.count, previous[index].configuration == item.configuration,
                  previous[index].choices == item.choices else { return item }
            return shuffledChoices(item, rng: &rng)
        }
    }

    private static func shuffledChoices(_ item: Item, rng: inout SeededRandom) -> Item {
        let count = item.choices.count
        guard count > 1 else { return item }
        var order = rng.shuffled(Array(0..<count))
        if order == Array(0..<count) { order = Array(order.dropFirst()) + [order[0]] }
        return item.reordered(order)
    }
}
