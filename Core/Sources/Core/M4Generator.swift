/// Round of the Math M4 level: build a number from bundles of ten and loose units.
public enum M4Generator {
    public static let itemsPerRound = 5
    static let drawLimit = 200

    /// One rule-produced question: its family and the numeral the visible model stands for.
    struct M4Spec: Equatable {
        let family: M4Family
        let numeral: Int

        var bundleCount: Int { numeral / 10 }
        var looseCount: Int { numeral % 10 }
        var configuration: Int { numeral * 10 + family.rawValue }
    }

    /// Every numeral the level covers, from 11 to 100 in rule order.
    static let numerals = Array(11...100)

    /// Every ruled configuration: each family on every numeral.
    static let specs: [M4Spec] = M4Family.allCases.flatMap { family in
        numerals.map { M4Spec(family: family, numeral: $0) }
    }

    /// The last question is an unfamiliar transfer: matching a model above fifty-nine.
    static let transferSpecs: [M4Spec] = specs.filter { $0.family == .matchModel && $0.numeral >= 60 }

    public static func items(seed: UInt64) -> [Item] {
        var rng = SeededRandom(seed: seed)
        var taken: Set<Int> = []
        var out: [Item] = []
        for position in 1...itemsPerRound {
            let pool = position == itemsPerRound ? transferSpecs : specs
            out.append(draw(from: pool, rng: &rng, taken: &taken).placed(at: position, of: itemsPerRound))
        }
        return out
    }

    /// Draws without replacement: the bounded walk skips configurations the round already holds.
    static func draw(from pool: [M4Spec], rng: inout SeededRandom, taken: inout Set<Int>) -> Item {
        let start = rng.below(pool.count)
        var chosen = pool[start]
        for offset in 0..<min(drawLimit, pool.count) {
            let spec = pool[(start + offset) % pool.count]
            if !taken.contains(spec.configuration) {
                chosen = spec
                break
            }
        }
        taken.insert(chosen.configuration)
        return item(chosen, rng: &rng)
    }

    /// Every ruled configuration as an item, for exhaustive content linting.
    public static func allConfigurations() -> [Item] {
        var rng = SeededRandom(seed: 0)
        return specs.map { item($0, rng: &rng) }
    }

    static func item(_ spec: M4Spec, rng: inout SeededRandom) -> Item {
        let options = options(for: spec, rng: &rng)
        var item = Item(kind: .counting, detail: .plain, options: options, configuration: spec.configuration)
        item.m4 = M4Presentation(family: spec.family, bundleCount: spec.bundleCount,
                                 looseCount: spec.looseCount, buttons: M4Presentation.standardButtons)
        return item
    }

    /// Three distinct choices with one correct numeral, each wrong one carrying its misconception.
    static func options(for spec: M4Spec, rng: inout SeededRandom) -> ItemOptions {
        let answer = spec.numeral
        var candidates: [(value: Int, tag: Misconception)] = []
        // Above fifty-nine a reversed numeral is the mistake the range is meant to catch.
        if (60...99).contains(answer), answer % 11 != 0 {
            candidates.append((reversed(answer), .wrongStep))
        }
        candidates.append((answer - spec.looseCount, .wrongStep))
        candidates.append((spec.bundleCount + spec.looseCount, .wrongStep))
        candidates.append((reversed(answer), .wrongStep))
        candidates.append((answer + 1, .offByOne))
        candidates.append((answer - 1, .offByOne))
        candidates.append((answer + 10, .wrongStep))
        candidates.append((answer - 10, .wrongStep))
        var wrong: [(value: Int, tag: Misconception)] = []
        var used: Set<Int> = [answer]
        for candidate in candidates where (0...100).contains(candidate.value)
            && used.insert(candidate.value).inserted {
            wrong.append(candidate)
            if wrong.count == 2 { break }
        }
        let correctIndex = rng.below(3)
        var choices = wrong.map(\.value)
        var tags: [Misconception?] = wrong.map(\.tag)
        choices.insert(answer, at: correctIndex)
        tags.insert(nil, at: correctIndex)
        return ItemOptions(choices: choices, correctIndex: correctIndex, misconceptions: tags)
    }

    static func reversed(_ number: Int) -> Int {
        (number % 10) * 10 + number / 10
    }
}
