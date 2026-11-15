// Finite domains use the same item builders as live rounds, not a random coverage estimate.
extension CountingBondsGenerator {
    public static func allConfigurations() -> [Item] {
        var rng = SeededRandom(seed: 0)
        var items = (1...10).map { total in
            Item(kind: .counting, operand: total,
                 options: wrongOptions(kind: .counting, operand: total, answer: total, rng: &rng))
        }
        for given in 0...10 {
            for fill in TenFrameFill.allCases {
                let options = wrongOptions(kind: .bond, operand: given, answer: 10 - given, rng: &rng)
                items.append(Item(kind: .bond, operand: given, options: options).filled(fill))
            }
        }
        for total in 2...10 {
            for first in 1..<total {
                let options = wrongOptions(kind: .counting, operand: total, answer: total, rng: &rng)
                items.append(groupedCounting(total: total, first: first, options: options))
            }
        }
        return items
    }

    static func groupedCounting(total: Int, first: Int, options: ItemOptions) -> Item {
        Item(kind: .counting, detail: .groups(first: first, second: total - first),
             options: options, configuration: 100 + total * 10 + first)
    }
}

extension AddSubGenerator {
    public static func allConfigurations() -> [Item] {
        var rng = SeededRandom(seed: 0)
        var items: [Item] = []
        for first in 1...17 {
            for second in 1...(19 - first) {
                items.append(addition(first: first, second: second, rng: &rng))
            }
        }
        for total in 2...20 {
            for crossed in 1...total {
                items.append(subtraction(total: total, crossed: crossed, rng: &rng))
            }
        }
        return items
    }
}

extension PatternsGenerator {
    public static func allConfigurations() -> [Item] {
        var rng = SeededRandom(seed: 0)
        var items: [Item] = []
        for step in 1...2 {
            for start in 0...(20 - step * (trackLength - 1)) {
                for missing in 0..<trackLength {
                    items.append(pattern(TrackConfiguration(start: start, step: step, missing: missing), rng: &rng))
                }
            }
        }
        for left in 0...20 {
            for offset in 2...19 {
                for larger in [true, false] {
                    let spec = ComparisonConfiguration(left: left, right: (left + offset) % 21, larger: larger)
                    items.append(comparison(spec, rng: &rng))
                }
            }
        }
        return items
    }
}
