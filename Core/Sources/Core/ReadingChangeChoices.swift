/// The three candidate words of a change-one-letter question: the target and two real words that also
/// differ from the stimulus word by exactly one letter.
enum ReadingChangeChoices {
    /// Real French words that may serve as wrong candidates next to the approved bank words.
    static let extraWords: [String] = [
        "mari", "mire", "male", "mure", "rame", "dame", "lame", "lime", "mine", "mite", "mime", "dime",
        "rime", "ride", "rude", "rade", "rire", "robe", "rose", "lobe", "rase", "sale", "sole", "pale",
        "pile", "pole", "pure", "pire", "pare", "pipe", "base", "bise", "case", "vase", "lune", "dune",
        "tune", "rune", "tube", "tuba", "cube", "cure", "lave", "cave", "mule", "mode", "rate", "sage"
    ]

    static func words(start: String, target: String) -> [String] {
        let pool = Array(Set(ReadingR2Change.vocabulary).union(extraWords)).sorted()
        let others = pool.filter { $0 != target && $0 != start && oneLetterApart($0, start) }
        return [target] + others.prefix(2)
    }

    private static func oneLetterApart(_ first: String, _ second: String) -> Bool {
        first.count == second.count && zip(first, second).filter { $0 != $1 }.count == 1
    }

    /// The three words with the target at `correctIndex`; empty when the bank item is not a change item.
    static func choices(bank: ReadingBankItem, correctIndex: Int) -> [String] {
        guard bank.r2Activity == .changeGrapheme, bank.words.count == 2 else { return [] }
        var rest = Array(words(start: bank.words[0], target: bank.words[1]).dropFirst())
        let index = min(max(correctIndex, 0), rest.count)
        rest.insert(bank.words[1], at: index)
        return rest
    }
}

extension Item {
    /// Candidate words of a change-one-letter question; empty for every other question.
    func changeLetterWords() -> [String] {
        guard !isNotice, let id = readingId, let bank = ReadingBank.item(id: id) else { return [] }
        return ReadingChangeChoices.choices(bank: bank, correctIndex: correctIndex)
    }
}

extension RoundViewModel {
    /// False for a kit round that has no feedback and no revealed help steps: no empty card is drawn.
    public var showsStimulusCard: Bool {
        kitPresentation == nil || feedbackText?.isEmpty == false || revealedHelpSteps > 0
    }
}
