/// The rungs of the French reading track, in teaching order.
public enum ReadingRung: CaseIterable, Equatable, Sendable {
    case r1, r2, r3

    var rank: Int { ReadingRung.allCases.firstIndex(of: self) ?? Int.max }
}

/// One written unit: a letter or a digraph.
public struct Grapheme: Equatable, Hashable, Sendable {
    public let text: String
}

/// A grapheme with the rung that first teaches it.
public struct Correspondence: Equatable, Sendable {
    public let grapheme: Grapheme
    public let rung: ReadingRung

    private static func rows(_ rung: ReadingRung, _ texts: [String]) -> [Correspondence] {
        texts.map { Correspondence(grapheme: Grapheme(text: $0), rung: rung) }
    }

    /// R1: familiar vowels and continuous consonants; R2: more consonants; R3: the digraphs ch and ou.
    public static let all: [Correspondence] =
        rows(.r1, ["a", "e", "i", "o", "u", "m", "s", "f", "r"])
        + rows(.r2, ["l", "n", "t", "p", "d", "b"])
        + rows(.r3, ["ch", "ou"])
}

public enum Decodability {
    public enum Result: Equatable, Sendable {
        case ok
        case untaught(String)
    }

    /// Greedy segmentation, two-letter graphemes first; names the first grapheme not taught at `rung` or earlier.
    public static func check(word: String, rung: ReadingRung) -> Result {
        let letters = Array(word.lowercased())
        var index = 0
        while index < letters.count {
            var piece = String(letters[index])
            if index + 1 < letters.count {
                let pair = String(letters[index...index + 1])
                if Correspondence.all.contains(where: { $0.grapheme.text == pair }) { piece = pair }
            }
            guard let found = Correspondence.all.first(where: { $0.grapheme.text == piece }),
                  found.rung.rank <= rung.rank else { return .untaught(piece) }
            index += piece.count
        }
        return .ok
    }
}

public struct ReadingWord: Equatable, Sendable {
    public let word: String
    public let rung: ReadingRung
}

public enum ReadingBank {
    private static func words(_ rung: ReadingRung, _ list: [String]) -> [ReadingWord] {
        list.map { ReadingWord(word: $0, rung: rung) }
    }

    public static let all: [ReadingWord] =
        words(.r1, ["ma", "mi", "sa", "si", "fa", "fi", "ro", "ru", "mur", "sur", "mer"])
        + words(.r2, ["lune", "pipe", "tapis", "dame", "nid", "robe"])
        + words(.r3, ["chou", "chat", "mouton", "souris", "mouche"])
}
