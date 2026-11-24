/// Words for the numbers 0...20 and the spoken form of formulas and number tracks.
enum SpokenMath {
    static let english = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
                          "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
                          "eighteen", "nineteen", "twenty"]
    static let french = ["zéro", "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf", "dix",
                         "onze", "douze", "treize", "quatorze", "quinze", "seize", "dix-sept", "dix-huit",
                         "dix-neuf", "vingt"]

    static func word(_ value: Int, _ language: Language) -> String {
        let words = language == .fr ? french : english
        return words.indices.contains(value) ? words[value] : String(value)
    }

    /// "three plus seven"; nil when the stimulus is not arithmetic.
    static func operation(_ detail: StimulusDetail, _ language: Language) -> String? {
        switch detail {
        case let .groups(first: first, second: second):
            return [word(first, language), TextTable.string("round.speech.plus", language),
                    word(second, language)].joined(separator: " ")
        case let .dots(total: total, crossedOut: crossed):
            return [word(total, language), TextTable.string("round.speech.minus", language),
                    word(crossed, language)].joined(separator: " ")
        default:
            return nil
        }
    }

    /// "10, 12, blank, 16, 18"; nil when the stimulus is not a number track.
    static func track(_ detail: StimulusDetail, _ language: Language) -> String? {
        guard case let .numberTrack(cells: cells, step: _) = detail else { return nil }
        let gap = TextTable.string("round.speech.blank", language)
        return cells.map { $0.shape == .emptyOutline ? gap : String($0.value) }.joined(separator: ", ")
    }
}
