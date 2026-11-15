/// Round of the patterns level: continue a number track, or pick the larger or smaller quantity.
public enum PatternsGenerator {
    public static let itemsPerRound = 5
    static let trackLength = 5

    public static func items(seed: UInt64) -> [Item] {
        var rng = SeededRandom(seed: seed)
        let kinds = MixedRound.kinds(.pattern, .comparison, count: itemsPerRound, rng: &rng)
        return kinds.enumerated().map { makeItem(kind: $0.element, rng: &rng).placed(at: $0.offset + 1, of: kinds.count) }
    }

    static func makeItem(kind: ItemKind, rng: inout SeededRandom) -> Item {
        kind == .pattern ? pattern(&rng) : comparison(&rng)
    }

    /// Five places stepping by 1 or 2 within 0...20; one place is the empty outlined slot.
    static func pattern(_ rng: inout SeededRandom) -> Item {
        let step = 1 + rng.below(2)
        let start = rng.below(20 - step * (trackLength - 1) + 1)
        let missing = rng.below(trackLength)
        return pattern(TrackConfiguration(start: start, step: step, missing: missing), rng: &rng)
    }

    struct TrackConfiguration {
        let start: Int
        let step: Int
        let missing: Int
    }

    static func pattern(_ configuration: TrackConfiguration, rng: inout SeededRandom) -> Item {
        let (start, step, missing) = (configuration.start, configuration.step, configuration.missing)
        let values = (0..<trackLength).map { start + $0 * step }
        let answer = values[missing]
        let cells = values.enumerated().map {
            TrackCell(value: $0.element, shape: $0.offset == missing ? .emptyOutline : .filled)
        }
        let other = 3 - step
        let wrongStep = missing > 0 ? values[missing - 1] + other : values[missing + 1] - other
        let candidates = rng.shuffled([
            OptionBuilder.Candidate(value: answer + 1, tag: .offByOne),
            OptionBuilder.Candidate(value: answer - 1, tag: .offByOne),
            OptionBuilder.Candidate(value: answer + 2, tag: .wrongStep),
            OptionBuilder.Candidate(value: answer - 2, tag: .wrongStep)
        ])
        let options = OptionBuilder.build(answer: answer,
                                          candidates: [.init(value: wrongStep, tag: .wrongStep)] + candidates,
                                          rng: &rng)
        return Item(kind: .pattern, detail: .numberTrack(cells: cells, step: step), options: options,
                    configuration: 3000 + (start * 2 + step - 1) * trackLength + missing)
    }

    /// Two quantities at least 2 apart; the child picks the larger or the smaller.
    static func comparison(_ rng: inout SeededRandom) -> Item {
        let left = rng.below(21)
        let right = (left + 2 + rng.below(18)) % 21
        let larger = rng.below(2) == 0
        return comparison(ComparisonConfiguration(left: left, right: right, larger: larger), rng: &rng)
    }

    struct ComparisonConfiguration {
        let left: Int
        let right: Int
        let larger: Bool
    }

    static func comparison(_ configuration: ComparisonConfiguration, rng: inout SeededRandom) -> Item {
        let (left, right, larger) = (configuration.left, configuration.right, configuration.larger)
        let answer = larger ? max(left, right) : min(left, right)
        let opposite = left + right - answer
        let towards = answer + (opposite > answer ? 1 : -1)
        let away = 2 * answer - towards
        let nearby = rng.shuffled([towards, away])
        let candidates = [OptionBuilder.Candidate(value: opposite, tag: .pickedTheOpposite)]
            + nearby.map { OptionBuilder.Candidate(value: $0, tag: .offByOne) }
        let options = OptionBuilder.build(answer: answer, candidates: candidates, rng: &rng)
        var item = Item(kind: .comparison, detail: .quantities(left: left, right: right), options: options,
                        configuration: 4000 + (left * 21 + right) * 2 + (larger ? 0 : 1))
        item.comparisonUsesLarger = larger
        return item
    }
}
