import Foundation

/// The graphemes each English rung teaches, cumulative: a rung may use its own and every earlier row.
enum ReadingENCorrespondences {
    static let en1 = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "r", "s",
                      "t", "u", "w", "x"]
    static let en2: [String] = []
    static let en3 = ["sh", "ch", "th"]

    /// Multi-letter graphemes the lint knows about, taught or not, so an untaught one is named.
    static let known = ["sh", "ch", "th", "ee", "ea", "oo", "ai", "oa", "ck", "ng", "qu", "ou", "ow", "ie"]

    static func taught(upTo rung: ReadingENRung) -> Set<String> {
        switch rung {
        case .en1: return Set(en1)
        case .en2: return Set(en1 + en2)
        case .en3: return Set(en1 + en2 + en3)
        }
    }

    /// Greedy segmentation, known digraphs first.
    static func segments(_ word: String) -> [String] {
        let letters = Array(word.lowercased().filter { $0 != " " })
        var out: [String] = []
        var index = 0
        while index < letters.count {
            var piece = String(letters[index])
            if index + 1 < letters.count {
                let pair = String(letters[index...index + 1])
                if known.contains(pair) { piece = pair }
            }
            out.append(piece)
            index += piece.count
        }
        return out
    }
}

extension ContentLint {
    static let minimumReadingENRungSize = 36

    /// Shipped French-to-English translations of reading words; an English item may not equal one.
    static let shippedFrenchTranslations: [String: [String]] = [
        "chou": ["cabbage"], "souris": ["mouse"], "mouton": ["sheep"],
        "mouche": ["fly"], "lune": ["moon"], "robe": ["dress"], "nid": ["nest"], "dame": ["lady"],
        "tapis": ["rug", "mat"], "pipe": ["pipe"]
    ]

    static var shippedFrenchWords: [String] { ReadingBank.all.map(\.word) }

    private static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func readingENFindings(
        _ items: [ReadingENItem],
        french: [String]? = nil,
        translations: [String: [String]]? = nil
    ) -> [ContentFinding] {
        let frenchWords = Set((french ?? shippedFrenchWords).map(normalized))
        let listed = translations ?? shippedFrenchTranslations
        var translated = Set<String>()
        for (word, english) in listed where frenchWords.contains(normalized(word)) {
            translated.formUnion(english.map(normalized))
        }
        var findings: [ContentFinding] = []
        for item in items {
            let taught = ReadingENCorrespondences.taught(upTo: item.rung)
            let used = item.graphemes + item.words.flatMap(ReadingENCorrespondences.segments)
            if let bad = used.first(where: { !taught.contains($0.lowercased()) }) {
                findings.append(ContentFinding(kind: "reading-en-undecodable", subject: "\(item.id):\(bad)"))
            }
            let texts = item.words.map(normalized)
            if texts.contains(where: { frenchWords.contains($0) || translated.contains($0) }) {
                findings.append(ContentFinding(kind: "reading-en-fr-overlap", subject: item.id))
            }
            if item.stimulus.visibleGraphemes.isEmpty && item.stimulus.tileChoices.isEmpty {
                findings.append(ContentFinding(kind: "reading-en-listening-only", subject: item.id))
            }
        }
        for rung in ReadingENRung.allCases where items.contains(where: { $0.rung == rung })
            && items.filter({ $0.rung == rung }).count < minimumReadingENRungSize {
            findings.append(ContentFinding(kind: "reading-en-rung-size", subject: rung.levelId))
        }
        return findings
    }
}
