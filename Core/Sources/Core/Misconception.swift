/// The mistake a wrong option stands for.
public enum Misconception: Sendable, Hashable {
    case addInsteadOfSubtract
    case offByOne
    case wrongStep
    case countedTheCrossedOut
    case pickedTheOpposite

    /// The misconceptions the generator of this kind may attach to its wrong options.
    public static func declared(for kind: ItemKind) -> [Misconception] {
        switch kind {
        case .counting: return [.offByOne, .wrongStep]
        case .bond: return [.offByOne, .wrongStep, .addInsteadOfSubtract]
        case .addition: return [.offByOne]
        case .subtraction: return [.addInsteadOfSubtract, .countedTheCrossedOut, .offByOne]
        case .pattern: return [.offByOne, .wrongStep]
        case .comparison: return [.pickedTheOpposite, .offByOne]
        }
    }
}

/// The three options of an item with the mistake behind each wrong one.
struct ItemOptions {
    let choices: [Int]
    let correctIndex: Int
    let misconceptions: [Misconception?]
}

/// Builds options: the answer plus the first two usable wrong candidates (in range, distinct).
enum OptionBuilder {
    struct Candidate {
        let value: Int
        let tag: Misconception
    }

    static func build(answer: Int, candidates: [Candidate], rng: inout SeededRandom) -> ItemOptions {
        var used: Set<Int> = [answer]
        var wrong: [Candidate] = []
        for candidate in candidates where (0...20).contains(candidate.value) && used.insert(candidate.value).inserted {
            wrong.append(candidate)
            if wrong.count == 2 { break }
        }
        let correctIndex = rng.below(3)
        var choices = wrong.map(\.value)
        var tags: [Misconception?] = wrong.map { $0.tag }
        choices.insert(answer, at: correctIndex)
        tags.insert(nil, at: correctIndex)
        return ItemOptions(choices: choices, correctIndex: correctIndex, misconceptions: tags)
    }
}
