public enum CountingBondsGenerator {
    public static let itemsPerRound = 5
    /// Make-ten items are always shown as 8 + ? = 10 (R-45).
    public static let bondGiven = 8
    private static let drawLimit = 200

    /// What a round position asks of the draw: the first make-ten example, the transfer slot, the keys in use.
    struct Slot {
        var firstBond = false
        var familiar = false
        var transfer = false
        var taken: Set<String> = []
    }

    public static func items(seed: UInt64) -> [Item] {
        var rng = SeededRandom(seed: seed)
        let extra: [ItemKind] = [.counting, .bond]
        let kinds: [ItemKind] = [.counting, .bond] + (0..<(itemsPerRound - 2)).map { _ in extra[rng.below(2)] }
        var slot = Slot()
        var bondSeen = false
        var out: [Item] = []
        for (index, kind) in rng.shuffled(kinds).enumerated() {
            slot.firstBond = kind == .bond && !bondSeen
            slot.familiar = index == 0
            slot.transfer = index == itemsPerRound - 1
            bondSeen = bondSeen || kind == .bond
            var item = makeItem(kind: kind, slot: slot, rng: &rng)
            var draws = 1
            while slot.taken.contains(key(item)), draws < drawLimit {
                item = makeItem(kind: kind, slot: slot, rng: &rng)
                draws += 1
            }
            slot.taken.insert(key(item))
            out.append(item.placed(at: index + 1, of: itemsPerRound))
        }
        return out
    }

    private static func key(_ item: Item) -> String { "\(item.kind.rawValue)-\(item.configuration)" }

    /// The first make-ten item of a round is always the 8 + ? = 10 example (R-45); later ones vary.
    /// The transfer slot uses the less familiar variant: grouped dots, or another frame layout.
    static func makeItem(kind: ItemKind, slot: Slot, rng: inout SeededRandom) -> Item {
        let operand: Int
        switch kind {
        case .bond:
            operand = slot.firstBond ? bondGiven : rng.below(11)
        default:
            operand = slot.transfer ? 2 + rng.below(9) : 1 + rng.below(10)
        }
        let answer = kind == .bond ? 10 - operand : operand
        let options = wrongOptions(kind: kind, operand: operand, answer: answer, rng: &rng)
        if kind == .bond {
            let pool = slot.firstBond || slot.familiar ? [TenFrameFill.rows] : TenFrameFill.allCases.filter { !slot.transfer || $0 != .rows }
            let item = plainItem(kind: kind, operand: operand, options: options)
            return item.filled(pool[rng.below(pool.count)])
        }
        if operand > 1 && !slot.familiar && (slot.transfer || rng.below(2) == 0) {
            return groupedCounting(total: operand, first: 1 + rng.below(operand - 1), options: options)
        }
        return plainItem(kind: kind, operand: operand, options: options)
    }

    private static func plainItem(kind: ItemKind, operand: Int, options: ItemOptions) -> Item {
        Item(kind: kind, operand: operand, options: options)
    }

    /// Three options: the answer and two wrong ones, each standing for a declared misconception.
    static func wrongOptions(kind: ItemKind, operand: Int, answer: Int, rng: inout SeededRandom) -> ItemOptions {
        typealias Candidate = OptionBuilder.Candidate
        var candidates: [Candidate] = [
            Candidate(value: answer + 1, tag: .offByOne), Candidate(value: answer - 1, tag: .offByOne),
            Candidate(value: answer + 2, tag: .wrongStep), Candidate(value: answer - 2, tag: .wrongStep)
        ]
        if kind == .bond { candidates.append(Candidate(value: operand, tag: .addInsteadOfSubtract)) }
        let usable = candidates.filter { (0...10).contains($0.value) }
        return OptionBuilder.build(answer: answer, candidates: rng.shuffled(usable), rng: &rng)
    }

    /// Splits `total` into groups of at most 5 dots.
    static func groups(total: Int) -> [Int] {
        var out: [Int] = []
        var left = total
        while left > 0 {
            let size = min(5, left)
            out.append(size)
            left -= size
        }
        return out
    }
}
