/// Round of the add-and-subtract level: addition with two groups, subtraction with crossed-out dots.
public enum AddSubGenerator {
    public static let itemsPerRound = 5

    public static func items(seed: UInt64) -> [Item] {
        var rng = SeededRandom(seed: seed)
        let kinds = MixedRound.kinds(.addition, .subtraction, count: itemsPerRound, rng: &rng)
        return kinds.enumerated().map { makeItem(kind: $0.element, rng: &rng).placed(at: $0.offset + 1, of: kinds.count) }
    }

    static func makeItem(kind: ItemKind, rng: inout SeededRandom) -> Item {
        kind == .addition ? addition(&rng) : subtraction(&rng)
    }

    /// a + b with a, b >= 1 and a sum of at most 19, so both off-by-one options stay in 0...20.
    static func addition(_ rng: inout SeededRandom) -> Item {
        let first = 1 + rng.below(17)
        let second = 1 + rng.below(19 - first)
        return addition(first: first, second: second, rng: &rng)
    }

    static func addition(first: Int, second: Int, rng: inout SeededRandom) -> Item {
        let sum = first + second
        let options = OptionBuilder.build(answer: sum, candidates: [
            .init(value: sum + 1, tag: .offByOne), .init(value: sum - 1, tag: .offByOne)
        ], rng: &rng)
        return Item(kind: .addition, detail: .groups(first: first, second: second), options: options,
                    configuration: 1000 + first * 21 + second)
    }

    /// a - b with 1 <= b <= a <= 20: the answer is the dots that are not crossed out.
    static func subtraction(_ rng: inout SeededRandom) -> Item {
        let total = 2 + rng.below(19)
        let crossed = 1 + rng.below(total)
        return subtraction(total: total, crossed: crossed, rng: &rng)
    }

    static func subtraction(total: Int, crossed: Int, rng: inout SeededRandom) -> Item {
        let left = total - crossed
        let candidates = rng.shuffled([
            OptionBuilder.Candidate(value: total + crossed, tag: .addInsteadOfSubtract),
            OptionBuilder.Candidate(value: crossed, tag: .countedTheCrossedOut),
            OptionBuilder.Candidate(value: left + 1, tag: .offByOne),
            OptionBuilder.Candidate(value: left - 1, tag: .offByOne)
        ])
        let options = OptionBuilder.build(answer: left, candidates: candidates, rng: &rng)
        return Item(kind: .subtraction, detail: .dots(total: total, crossedOut: crossed), options: options,
                    configuration: 2000 + total * 21 + crossed)
    }
}

enum MixedRound {
    /// `count` kinds containing both given kinds at least once, in a shuffled order.
    static func kinds(_ first: ItemKind, _ second: ItemKind, count: Int, rng: inout SeededRandom) -> [ItemKind] {
        let pair = [first, second]
        let extra = (0..<(count - 2)).map { _ in pair[rng.below(2)] }
        return rng.shuffled(pair + extra)
    }
}
