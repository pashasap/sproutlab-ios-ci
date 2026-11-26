/// Round of the Math M3 level: make ten, take away through ten, and an equivalent easier calculation.
public enum M3Generator {
    public static let itemsPerRound = 5
    static let drawLimit = 64

    /// One ruled question: its family, the example it stands for, the two frame counts and the removal.
    struct M3Spec {
        let family: M3Family
        let example: M3Example?
        let counts: (Int, Int)
        let remove: Int
    }

    /// Every ruled configuration, built from the rules rather than sampled.
    static let specs: [M3Spec] = {
        var out: [M3Spec] = []
        // Make-ten splits: the first frame is not full, the two frames reach at least ten.
        for first in 1...9 {
            for second in max(1, 10 - first)...10 {
                out.append(M3Spec(family: .makeTen, example: nil, counts: (first, second), remove: 0))
            }
        }
        // Remove through ten: more than ten shown, a positive removal, fewer than ten left.
        for total in 11...20 {
            let first = min(10, total - 1)
            for answer in 0...9 {
                out.append(M3Spec(family: .removeThroughTen, example: nil,
                                  counts: (first, total - first), remove: total - answer))
            }
        }
        // Equivalent easier calculations: doubles, near-doubles and crossing-ten pairs.
        for value in 0...10 {
            out.append(M3Spec(family: .equivalent, example: .doubles, counts: (value, value), remove: 0))
        }
        for lower in 0...9 {
            out.append(M3Spec(family: .equivalent, example: .nearDoubles, counts: (lower, lower + 1), remove: 0))
        }
        for first in 1...9 {
            for second in (11 - first)...10 {
                out.append(M3Spec(family: .equivalent, example: .crossingTen, counts: (first, second), remove: 0))
            }
        }
        return out
    }()

    /// The last question is always an unfamiliar transfer: a crossing-ten or a take-away pair.
    static let transferSpecs: [M3Spec] = specs.filter {
        ($0.family == .equivalent && $0.example == .crossingTen) || $0.family == .removeThroughTen
    }

    public static func items(seed: UInt64) -> [Item] {
        var rng = SeededRandom(seed: seed)
        var taken: Set<Int> = []
        var out: [Item] = []
        for position in 1...itemsPerRound {
            let pool = position == itemsPerRound ? transferSpecs : specs
            let item = draw(from: pool, rng: &rng, taken: &taken)
            out.append(item.placed(at: position, of: itemsPerRound))
        }
        return out
    }

    /// Draws without replacement: the bounded walk skips configurations the round already holds.
    static func draw(from pool: [M3Spec], rng: inout SeededRandom, taken: inout Set<Int>) -> Item {
        let start = rng.below(pool.count)
        var chosen = pool[start]
        for offset in 0..<drawLimit {
            let spec = pool[(start + offset) % pool.count]
            if !taken.contains(configuration(spec)) {
                chosen = spec
                break
            }
        }
        taken.insert(configuration(chosen))
        return item(chosen, rng: &rng)
    }

    /// Every ruled configuration as an item, for exhaustive content linting.
    public static func allConfigurations() -> [Item] {
        var rng = SeededRandom(seed: 0)
        return specs.map { item($0, rng: &rng) }
    }

    static func configuration(_ spec: M3Spec) -> Int {
        let example = spec.example.map { $0.rawValue + 1 } ?? 0
        return spec.family.rawValue * 10_000_000 + example * 1_000_000
            + spec.counts.0 * 10_000 + spec.counts.1 * 100 + spec.remove
    }

    static func item(_ spec: M3Spec, rng: inout SeededRandom) -> Item {
        let total = spec.counts.0 + spec.counts.1
        let answer = total - spec.remove
        let options = OptionBuilder.build(answer: answer, candidates: candidates(spec, total: total, answer: answer),
                                          rng: &rng)
        var item = Item(kind: .subtraction, detail: .dots(total: total, crossedOut: spec.remove),
                        options: options, configuration: configuration(spec))
        item.m3 = M3Presentation(family: spec.family, example: spec.example,
                                 counts: [spec.counts.0, spec.counts.1], removeAmount: spec.remove)
        return item
    }

    /// Two plausible wrong values, each with the mistake it stands for.
    static func candidates(_ spec: M3Spec, total: Int, answer: Int) -> [OptionBuilder.Candidate] {
        var out: [OptionBuilder.Candidate] = []
        if spec.family == .removeThroughTen {
            out.append(.init(value: spec.remove, tag: .countedTheCrossedOut))
            out.append(.init(value: total, tag: .wrongStep))
        } else {
            out.append(.init(value: spec.counts.0, tag: .wrongStep))
            out.append(.init(value: spec.counts.1, tag: .wrongStep))
        }
        out.append(.init(value: answer + 1, tag: .offByOne))
        out.append(.init(value: answer - 1, tag: .offByOne))
        out.append(.init(value: answer + 2, tag: .offByOne))
        return out
    }
}
