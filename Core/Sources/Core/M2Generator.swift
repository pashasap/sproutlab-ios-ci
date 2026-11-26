/// Round of the Math M2 level: fill a ten-frame, pick the two baskets that make a total, complete an equation.
public enum M2Generator {
    public static let itemsPerRound = 5
    static let drawLimit = 200
    static let lowestTotal = 3
    static let highestTotal = 10

    public static func items(seed: UInt64) -> [Item] {
        var rng = SeededRandom(seed: seed)
        let extra = (0..<(itemsPerRound - M2QuestionKind.allCases.count)).map { _ in
            M2QuestionKind.allCases[rng.below(M2QuestionKind.allCases.count)]
        }
        let kinds = rng.shuffled(M2QuestionKind.allCases + extra)
        var taken: Set<Int> = []
        var out: [Item] = []
        var ordinals: [M2QuestionKind: Int] = [:]
        for (index, kind) in kinds.enumerated() {
            let ordinal = ordinals[kind, default: 0]
            var item = draw(kind: kind, ordinal: ordinal, seed: seed)
            var draws = 1
            while taken.contains(item.configuration) && draws < drawLimit {
                item = draw(kind: kind, ordinal: ordinal + draws, seed: seed)
                draws += 1
            }
            ordinals[kind] = ordinal + 1
            taken.insert(item.configuration)
            out.append(item.placed(at: index + 1, of: kinds.count))
        }
        return out
    }

    /// Every ordered partition (part, part) of the totals 3 to 10; the draw walks it so seeds cover it all.
    static let partitions: [(filled: Int, empty: Int)] = {
        var out: [(filled: Int, empty: Int)] = []
        for total in lowestTotal...highestTotal {
            for first in 0...total { out.append((filled: first, empty: total - first)) }
        }
        return out
    }()

    static func draw(kind: M2QuestionKind, ordinal: Int, seed: UInt64) -> Item {
        let index = (Int(seed % UInt64(partitions.count)) + ordinal * 7) % partitions.count
        let partition = partitions[index]
        let missing: M2Slot = kind == .missingPart
            ? ((Int(seed) + ordinal) % 2 == 0 ? .first : .second) : .total
        return item(kind: kind, first: partition.filled, second: partition.empty, missing: missing)
    }

    /// Every partition of every total from 3 to 10, including the zero parts, for each kind.
    public static func allConfigurations() -> [Item] {
        var out: [Item] = []
        for kind in M2QuestionKind.allCases {
            for total in lowestTotal...highestTotal {
                for first in 0...total {
                    let slots: [M2Slot] = kind == .missingPart ? [.first, .second] : [.total]
                    for slot in slots {
                        out.append(item(kind: kind, first: first, second: total - first, missing: slot))
                    }
                }
            }
        }
        return out
    }

    static func configuration(kind: M2QuestionKind, first: Int, second: Int, missing: M2Slot) -> Int {
        kind.rawValue * 10_000_000 + missing.rawValue * 1_000_000 + first * 100 + second
    }

    static func item(kind: M2QuestionKind, first: Int, second: Int, missing: M2Slot) -> Item {
        let answer = answerValue(kind: kind, first: first, second: second, missing: missing)
        let id = configuration(kind: kind, first: first, second: second, missing: missing)
        var rng = SeededRandom(seed: UInt64(id))
        let options = OptionBuilder.build(answer: answer,
                                          candidates: candidates(kind: kind, first: first,
                                                                 second: second, answer: answer),
                                          rng: &rng)
        var item = Item(kind: .bond, operand: first + second, options: options)
        item.configuration = id
        let part = Part(kind: kind, first: first, second: second, missing: missing)
        item.m2 = presentation(part, options: options)
        return item
    }

    /// One drawn question: the kind, its two parts and, for a missing-part equation, the hidden slot.
    struct Part {
        let kind: M2QuestionKind
        let first: Int
        let second: Int
        let missing: M2Slot
    }

    /// The value the child must give: the empty spaces, the total, or the hidden part.
    static func answerValue(kind: M2QuestionKind, first: Int, second: Int, missing: M2Slot) -> Int {
        switch kind {
        case .fillTenFrame: return second
        case .pickBaskets: return first + second
        case .missingPart: return missing == .first ? first : second
        }
    }

    /// Two plausible wrong values, each with the mistake it stands for.
    static func candidates(kind: M2QuestionKind, first: Int, second: Int,
                           answer: Int) -> [OptionBuilder.Candidate] {
        let total = first + second
        switch kind {
        case .fillTenFrame:
            return [.init(value: first, tag: .wrongStep),
                    .init(value: answer + 1, tag: .offByOne),
                    .init(value: answer - 1, tag: .offByOne)]
        case .pickBaskets:
            return [.init(value: first, tag: .wrongStep),
                    .init(value: total + 1, tag: .offByOne),
                    .init(value: answer - 1, tag: .offByOne),
                    .init(value: second, tag: .wrongStep)]
        case .missingPart:
            return [.init(value: total, tag: .wrongStep),
                    .init(value: answer + 1, tag: .offByOne),
                    .init(value: answer - 1, tag: .offByOne)]
        }
    }

    static func presentation(_ part: Part, options: ItemOptions) -> M2Presentation {
        let first = part.first
        let second = part.second
        let total = first + second
        let equation: M2Equation
        let frame: M2TenFrame
        switch part.kind {
        case .fillTenFrame:
            equation = M2Equation(first: first, second: second, total: total, missing: .total)
            frame = M2TenFrame(filled: Array(0..<first), empty: Array(first..<total))
        case .pickBaskets:
            equation = M2Equation(first: first, second: second, total: total, missing: .total)
            frame = M2TenFrame(filled: [], empty: [])
        case .missingPart:
            if part.missing == .first {
                equation = M2Equation(first: nil, second: second, total: total, missing: .first)
                frame = M2TenFrame(filled: Array(0..<second), empty: Array(second..<total))
            } else {
                equation = M2Equation(first: first, second: nil, total: total, missing: .second)
                frame = M2TenFrame(filled: Array(0..<first), empty: Array(first..<total))
            }
        }
        let baskets = part.kind == .pickBaskets ? [M2Basket(count: first), M2Basket(count: second)] : []
        let choiceBaskets = part.kind == .pickBaskets ? options.choices.map { split($0) } : []
        var shown = M2Presentation(kind: part.kind, frame: frame, targetTotal: total, equation: equation)
        shown.baskets = baskets
        shown.choiceBaskets = choiceBaskets
        return shown
    }

    /// A choice total shown as two baskets whose counts add up to it.
    static func split(_ value: Int) -> [M2Basket] {
        [M2Basket(count: value / 2), M2Basket(count: value - value / 2)]
    }
}
