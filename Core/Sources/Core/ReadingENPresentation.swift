/// The English reading question as the child sees it: an English prompt, a written stimulus and three
/// text choices. The text is authored English and does not change with the interface language.
enum ReadingENPresenter {
    private static let letterPool = ["a", "e", "i", "o", "u", "b", "d", "f", "g", "h", "j", "k", "l", "m", "n",
                                     "p", "r", "s", "t"]
    private static let digraphPool = ["sh", "ch", "th", "wh", "ph", "ck"]

    static func prompt(_ bank: ReadingENItem) -> String {
        switch bank.activity {
        case .graphemeSound: return "Find the letter you see."
        case .cvcSequence: return "Which word do you see?"
        case .readReveal: return "Read the word."
        case .changeGrapheme: return "Which letter changed?"
        case .buildTiles: return "Build the word."
        case .digraph: return "Which two letters go together?"
        case .blend: return "Read the blend."
        case .repairSplit: return "Which word is the fixed one?"
        }
    }

    static func stimulus(_ bank: ReadingENItem) -> String {
        switch bank.activity {
        case .graphemeSound: return bank.graphemes.first ?? ""
        case .changeGrapheme, .repairSplit: return bank.words.joined(separator: " → ")
        default: return bank.words.first ?? bank.graphemes.joined()
        }
    }

    /// The right text and the pool its two wrong companions come from.
    private static func answer(_ bank: ReadingENItem) -> (right: String, pool: [String]) {
        switch bank.activity {
        case .graphemeSound: return (bank.graphemes.first ?? "", letterPool)
        case .digraph: return (bank.graphemes.first ?? "", digraphPool)
        case .changeGrapheme:
            let pair = zip(bank.words[0], bank.words[1]).first { $0 != $1 }
            return (pair.map { String($0.1) } ?? "", letterPool)
        default:
            let right = bank.words.last ?? ""
            let words = ReadingENBank.items(rung: bank.rung).flatMap(\.words).filter { !$0.contains(" ") }
            return (right, Array(Set(words)).sorted())
        }
    }

    static func choiceTexts(_ bank: ReadingENItem, correctIndex: Int) -> [String] {
        let (right, pool) = answer(bank)
        let others = pool.filter { $0 != right && Int($0) == nil }
        let start = others.isEmpty ? 0 : abs(right.hashValueFree) % others.count
        var rest = (0..<2).map { others[(start + $0) % others.count] }
        rest.insert(right, at: min(max(correctIndex, 0), 2))
        return rest
    }
}

private extension String {
    /// A stable number from the characters; Swift's hashValue changes between runs.
    var hashValueFree: Int { unicodeScalars.reduce(7) { ($0 &* 31 &+ Int($1.value)) % 100_003 } }
}

extension Item {
    func englishReadingPresentation(_ bank: ReadingENItem, _ language: Language) -> ReadingItemPresentation {
        let label = TextTable.string("reading.choice.label", language)
        let choices = ReadingENPresenter.choiceTexts(bank, correctIndex: correctIndex).map {
            ReadingChoicePresentation(text: $0, accessibilityLabel: label + " " + $0)
        }
        var result = ReadingItemPresentation(dotStimulusCount: 0, choices: choices, orderingTiles: [],
                                             slotCount: 0, boardTiles: [])
        result.stimulusWord = ReadingENPresenter.stimulus(bank)
        result.promptText = ReadingENPresenter.prompt(bank)
        return result
    }
}
