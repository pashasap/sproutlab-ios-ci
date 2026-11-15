public enum ReadingR3Activity: CaseIterable, Equatable, Sendable {
    case selectDigraph, blendWord, repairSplit
}

/// The authored data of one R3 item: the activity, the word and the digraph it is about.
struct ReadingR3Spec {
    let activity: ReadingR3Activity
    let word: String
    let grapheme: String
}

extension ReadingBank {
    static let r3Digraphs = ["ch", "ou"]

    /// The graphemes of a word in order; ch and ou count as one unit each.
    static func r3Segments(_ word: String) -> [String] {
        let letters = Array(word)
        var out: [String] = []
        var index = 0
        while index < letters.count {
            let pair = index + 1 < letters.count ? String(letters[index...index + 1]) : ""
            let step = r3Digraphs.contains(pair) ? 2 : 1
            out.append(step == 2 ? pair : String(letters[index]))
            index += step
        }
        return out
    }

    private static func specs(_ activity: ReadingR3Activity, _ grapheme: String, _ words: String) -> [ReadingR3Spec] {
        words.split(separator: " ").map { ReadingR3Spec(activity: activity, word: String($0), grapheme: grapheme) }
    }

    static let r3Specs: [ReadingR3Spec] =
        specs(.selectDigraph, "ch", "chat chute chemin chalet riche poche")
        + specs(.selectDigraph, "ou", "loup pour four soupe boule poule")
        + specs(.blendWord, "ch", "chaton chaise chien biche niche fiche")
        + specs(.blendWord, "ou", "souris mouton fourmi route moule doute")
        + specs(.repairSplit, "ch", "roche tache mache chimie chine chou")
        + specs(.repairSplit, "ou", "foule loupe toute rouler boue sourd")

    private static func r3Slug(_ activity: ReadingR3Activity) -> String {
        switch activity {
        case .selectDigraph: return "select"
        case .blendWord: return "blend"
        case .repairSplit: return "repair"
        }
    }

    static let r3Items: [ReadingBankItem] = {
        var counters: [ReadingR3Activity: Int] = [:]
        let ids = r3Specs.map { spec -> String in
            let number = (counters[spec.activity] ?? 0) + 1
            counters[spec.activity] = number
            return "r3-\(r3Slug(spec.activity))-\(number < 10 ? "0" : "")\(number)"
        }
        return r3Specs.indices.map { index in
            let spec = r3Specs[index]
            let same = r3Specs.indices.filter { r3Specs[$0].activity == spec.activity }
            let position = same.firstIndex(of: index) ?? 0
            return r3Item(spec, id: ids[index], transferId: ids[same[(position + 1) % same.count]], position: position)
        }
    }()

    private static func r3Palette(_ spec: ReadingR3Spec, tokens: [String], position: Int) -> [String] {
        var palette: [String]
        switch spec.activity {
        case .selectDigraph:
            let others = tokens.filter { $0 != spec.grapheme }.prefix(2)
            palette = [spec.grapheme] + others
        case .blendWord:
            let decoys = (r3Digraphs + ["a", "e", "i", "l"]).filter { !tokens.contains($0) }
            palette = tokens + decoys.prefix(2)
        case .repairSplit:
            return tokens
        }
        let shift = position % palette.count
        return Array(palette[shift...] + palette[..<shift])
    }

    private static func r3Item(_ spec: ReadingR3Spec, id: String, transferId: String, position: Int) -> ReadingBankItem {
        let segments = r3Segments(spec.word)
        let tokens: [String]
        switch spec.activity {
        case .selectDigraph: tokens = []
        case .blendWord: tokens = segments
        case .repairSplit: tokens = spec.grapheme.map { String($0) }
        }
        let palette = r3Palette(spec, tokens: spec.activity == .selectDigraph ? segments : tokens, position: position)
        var item = ReadingBankItem(
            id: id, rung: .r3, status: .approved, activity: spec.activity == .selectDigraph ? .tapGrapheme : .blendNew,
            grapheme: spec.grapheme, tokens: tokens, palette: palette, words: [spec.word],
            speechItem: ReadingItem(kind: .word, text: spec.word),
            misconceptionCheck: r3Misconception(spec), independentAnswer: spec.activity == .selectDigraph ? .tap : .kit,
            workedHintKey: "reading.hint.r3." + id, transferId: transferId, needsSound: false)
        item.r3Activity = spec.activity
        return item
    }

    private static func r3Misconception(_ spec: ReadingR3Spec) -> String {
        let unit = spec.grapheme, word = spec.word
        switch spec.activity {
        case .selectDigraph:
            return "Lit-il « \(unit) » dans « \(word) » comme deux lettres séparées au lieu d'une seule unité ?"
        case .blendWord:
            return "Découpe-t-il « \(unit) » en deux sons quand il lit « \(word) » ?"
        case .repairSplit:
            return "Oublie-t-il que les lettres « \(unit) » de « \(word) » vont ensemble et forment un seul son ?"
        }
    }
}
