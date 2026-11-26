/// The French sentence bank of the r6 level: 24 sentences, eight of each kind.
public enum FrenchSentenceBank {
    /// Every grapheme the French rungs teach; a sentence word may use only these.
    static let multiLetterGraphemes = ["ch", "ou"]

    /// Splits a spelling into its graphemes, two-letter graphemes first; case is kept by the caller.
    static func graphemes(of text: String) -> [String] {
        let letters = Array(text.lowercased())
        var out: [String] = []
        var index = 0
        while index < letters.count {
            if index + 1 < letters.count {
                let pair = String(letters[index...index + 1])
                if multiLetterGraphemes.contains(pair) {
                    out.append(pair)
                    index += 2
                    continue
                }
            }
            out.append(String(letters[index]))
            index += 1
        }
        return out
    }

    static func word(_ text: String, sight: Bool = false) -> SentenceWord {
        SentenceWord(text: text, graphemes: sight ? [] : graphemes(of: text), isSight: sight)
    }

    static func item(_ number: Int, _ kind: SentenceKind, _ words: [SentenceWord]) -> SentenceItem {
        SentenceItem(id: String(format: "fr-r6-%02d", number), kind: kind, words: words)
    }

    /// Determiners and `est` are read whole; every other word is segmented.
    static func sight(_ text: String) -> SentenceWord { word(text, sight: true) }

    public static let items: [SentenceItem] = complete + scene + order

    /// Complete the sentence: the child picks the word that fills the blank.
    static let complete: [SentenceItem] = [
        item(1, .complete, [sight("Le"), word("chat"), word("dort"), word("sur"), sight("le"), word("mur")]),
        item(2, .complete, [sight("La"), word("lune"), word("ronde"), word("brille")]),
        item(3, .complete, [sight("Un"), word("ours"), word("dort"), word("sous"), sight("la"), word("table")]),
        item(4, .complete, [sight("La"), word("petite"), word("fille"), word("lit"), word("dans"), sight("le"),
                           word("nid")]),
        item(5, .complete, [sight("Le"), word("mouton"), word("sort"), word("du"), word("bois")]),
        item(6, .complete, [sight("Le"), word("poisson"), word("sort"), word("du"), word("bain")]),
        item(7, .complete, [sight("Le"), word("chou"), word("pousse"), word("dans"), sight("le"), word("pot")]),
        item(8, .complete, [sight("Un"), word("lapin"), word("saute"), word("sur"), sight("le"), word("mur")])
    ]

    /// Pick the scene: both scenes share their objects and differ in one sentence-named detail.
    static let scene: [SentenceItem] = [
        item(9, .scene, [sight("Le"), word("chat"), word("noir"), word("dort"), word("sur"), sight("le"),
                         word("mur")]),
        item(10, .scene, [sight("Le"), word("petit"), word("chou"), word("pousse"), word("sous"), sight("la"),
                          word("table")]),
        item(11, .scene, [sight("La"), word("lune"), word("ronde"), word("luit"), word("sur"), sight("le"),
                          word("toit")]),
        item(12, .scene, [sight("La"), word("feuille"), word("fine"), word("tombe"), word("sur"), sight("le"),
                          word("sable")]),
        item(13, .scene, [sight("Le"), word("lapin"), word("petit"), word("saute"), word("dans"), sight("le"),
                          word("nid")]),
        item(14, .scene, [sight("Le"), word("poisson"), word("rond"), word("sort"), word("de"), sight("la"),
                          word("tasse")]),
        item(15, .scene, [sight("Le"), word("renard"), word("dort"), word("sous"), sight("le"), word("pommier")]),
        item(16, .scene, [sight("La"), word("pomme"), word("mure"), word("est"), word("dans"), sight("le"),
                          word("panier")])
    ]

    /// Put the words in order: every sentence has two to five distinct words.
    static let order: [SentenceItem] = [
        item(17, .order, [sight("Le"), word("chat"), word("dort")]),
        item(18, .order, [sight("La"), word("lune"), word("brille")]),
        item(19, .order, [sight("Le"), word("lapin"), word("saute")]),
        item(20, .order, [sight("Un"), word("ours"), word("dort")]),
        item(21, .order, [sight("La"), word("porte"), word("tombe")]),
        item(22, .order, [sight("Le"), word("nid"), word("tombe")]),
        item(23, .order, [sight("Un"), word("mur"), word("rond"), word("tombe")]),
        item(24, .order, [word("Petit"), word("chou"), word("pousse")])
    ]

    public static func item(id: String) -> SentenceItem? {
        items.first { $0.id == id }
    }
}

/// The decodability checker of the sentence bank: an empty result means the sentence passes.
public enum SentenceDecodability {
    /// Every grapheme the French reading rungs teach.
    public static let taughtGraphemes: Set<String> = Set(
        Correspondence.all.map { $0.grapheme.text.lowercased() }
    ).union(["ch", "ou"])

    /// The whole words a sentence may use instead of segmenting them.
    public static let sightWords: Set<String> = ["le", "la", "les", "un", "une", "est", "et"]

    public static let maximumSightShare = 0.45
    public static let minimumSegmentedWords = 2

    public static func check(_ item: SentenceItem) -> [String] {
        var findings: [String] = []
        if item.words.isEmpty { return ["empty sentence"] }
        findings += item.words.flatMap { wordFindings($0, id: item.id) }
        let sight = item.words.filter(\.isSight).count
        if Double(sight) > maximumSightShare * Double(item.words.count) {
            findings.append("\(item.id): sight share above limit")
        }
        let segmented = item.words.filter { !$0.isSight && !$0.graphemes.isEmpty }.count
        if segmented < minimumSegmentedWords {
            findings.append("\(item.id): fewer than two segmented words")
        }
        if item.sentence != item.words.map(\.text).joined(separator: " ") {
            findings.append("\(item.id): sentence does not join its words")
        }
        return findings
    }

    static func wordFindings(_ word: SentenceWord, id: String) -> [String] {
        if word.isSight {
            return sightWords.contains(word.text.lowercased()) ? [] : ["\(id): unlisted sight word \(word.text)"]
        }
        if word.graphemes.isEmpty { return ["\(id): segmented word \(word.text) has no graphemes"] }
        var findings: [String] = []
        for token in word.graphemes {
            if token.hasPrefix("~") {
                let letter = String(token.dropFirst()).lowercased()
                if !["e", "s", "t"].contains(letter) { findings.append("\(id): silent letter \(token)") }
            } else if !taughtGraphemes.contains(token.lowercased()) {
                findings.append("\(id): untaught grapheme \(token)")
            }
        }
        let joined = word.graphemes.map { $0.replacingOccurrences(of: "~", with: "") }.joined()
        if joined.lowercased() != word.text.lowercased() {
            findings.append("\(id): graphemes do not spell \(word.text)")
        }
        return findings
    }
}
