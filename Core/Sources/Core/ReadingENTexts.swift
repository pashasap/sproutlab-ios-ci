extension TextTable {
    /// English-only reading content: both locales carry the same English wording, so a French app
    /// never serves a French item or French help inside the readingEN track.
    private static func english(_ text: String) -> TextEntry { TextEntry("EN: " + text, text) }

    private static let readingENHelp: [String: TextEntry] = [
        "reading.en.help.en1.1": english("Say the sound of each letter slowly, one at a time."),
        "reading.en.help.en1.2": english("Point at each letter and say its sound out loud."),
        "reading.en.help.en1.3": english("Slide the sounds together until they make one word."),
        "reading.en.help.en2.1": english("Tap each letter and say its sound first, then say the whole word."),
        "reading.en.help.en2.2": english("Say the first two sounds together, then add the last one."),
        "reading.en.help.en2.3": english("Check the middle vowel, then read the whole word again."),
        "reading.en.help.en3.1": english("Look for two letters that team up to make one sound."),
        "reading.en.help.en3.2": english("Keep a team of letters together and say it as one sound."),
        "reading.en.help.en3.3": english("Say every sound in a row, then run them together.")
    ]

    private static let readingENChrome: [String: TextEntry] = [
        "trail.level.reading-en-en1.title": TextEntry("Lettres et sons", "Letters and sounds"),
        "trail.level.reading-en-en2.title": TextEntry("Mots courts", "Short words"),
        "trail.level.reading-en-en3.title": TextEntry("Groupes de lettres", "Letter teams")
    ]

    static let readingENTexts: [String: TextEntry] = {
        var texts = readingENHelp.merging(readingENChrome) { first, _ in first }
        for item in ReadingENBank.allItems { texts[item.workedHintKey] = english(workedHintEN(item)) }
        // Built from the word list, not from the recipes: building a Recipe reads the text table.
        for word in ReadingENBank.revealWords {
            texts["recipe.en-\(word).name"] = english("a " + word)
            texts["recipe.en-\(word).description"] = english("A picture of a " + word + ".")
        }
        return texts
    }()

    private static func workedHintEN(_ item: ReadingENItem) -> String {
        let word = item.words.first ?? ""
        let unit = item.graphemes.joined(separator: ", ")
        switch item.activity {
        case .graphemeSound:
            return "Example: the letter \(unit) says \(item.phonemes.joined()). Say it with me."
        case .cvcSequence:
            return "Example: \(unit) say \(item.phonemes.joined(separator: " ")). Push them together: \(word)."
        case .readReveal:
            return "Example: say each sound in \(word.map(String.init).joined(separator: ", ")), then read the word."
        case .changeGrapheme:
            return "Example: change just one letter of \(word) to make \(item.words.last ?? word)."
        case .buildTiles:
            return "Example: to build \(word), place the tiles in order: \(word.map(String.init).joined(separator: ", "))."
        case .digraph:
            return "Example: in \(word), the letters \(unit) work as one team and make one sound."
        case .blend:
            return "Example: in \(word), say each sound in a row: \(unit). Then run them together."
        case .repairSplit:
            return "Example: \(unit) belong together, so join them back to make \(item.words.last ?? word)."
        }
    }
}
