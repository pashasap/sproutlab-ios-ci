public enum ReadingR2Activity: CaseIterable, Equatable, Sendable {
    case decodeReveal, changeGrapheme, buildWord
}

/// The authored data of one R2 item before ids, checks and hint keys are derived.
struct ReadingR2Spec {
    let activity: ReadingR2Activity
    let words: [String]
    let palette: [String]
    let picture: String?
}

extension ReadingBank {
    private static func reveal(_ word: String, _ picture: String, _ others: String) -> ReadingR2Spec {
        let options = [word] + others.split(separator: " ").map(String.init)
        return ReadingR2Spec(activity: .decodeReveal, words: [word], palette: options, picture: picture)
    }

    /// Start and target differ by one letter; the palette holds both letters and the extra letters.
    private static func change(_ start: String, _ target: String, _ extra: String) -> ReadingR2Spec {
        let pair = zip(start, target).first { $0 != $1 }
        let letters = [pair.map { String($0.1) } ?? "", pair.map { String($0.0) } ?? ""] + extra.map { String($0) }
        return ReadingR2Spec(activity: .changeGrapheme, words: [start, target], palette: letters, picture: nil)
    }

    private static func build(_ word: String, _ extra: String) -> ReadingR2Spec {
        let palette = word.map { String($0) } + extra.map { String($0) }
        return ReadingR2Spec(activity: .buildWord, words: [word], palette: palette, picture: nil)
    }

    static let r2Specs: [ReadingR2Spec] = [
        reveal("lune", "moon", "dune lame"), reveal("rose", "rose", "robe rame"),
        reveal("robe", "dress", "rose mode"), reveal("pipe", "pipe", "pile pipi"),
        reveal("tipi", "tipi", "pipi tapi"), reveal("dodo", "dodo", "dada bobo"),
        reveal("lama", "llama", "lima lame"), reveal("dune", "dune", "lune dine"),
        reveal("tuba", "tuba", "tube tuna"), reveal("sofa", "sofa", "soda safa"),
        reveal("mare", "pond", "rare mari"), reveal("mule", "mule", "mile mure"),
        change("lame", "lime", "ou"), change("robe", "rose", "ft"), change("mare", "rare", "sl"),
        change("sale", "sole", "iu"), change("dame", "lame", "pt"), change("rime", "rame", "ou"),
        change("mine", "mire", "tp"), change("tube", "tuba", "io"), change("ride", "rude", "ao"),
        change("pire", "pure", "eo"), change("base", "bise", "ou"), change("lune", "dune", "mf"),
        build("dame", "ip"), build("tube", "ao"), build("rame", "ui"), build("fine", "as"),
        build("pure", "ol"), build("base", "ut"), build("rire", "ao"), build("sale", "ot"),
        build("pile", "ur"), build("mode", "ai"), build("du", "ot"), build("ta", "ie")
    ]

    static let r2Items: [ReadingBankItem] = {
        var counters: [ReadingR2Activity: Int] = [:]
        let ids = r2Specs.map { spec -> String in
            let number = (counters[spec.activity] ?? 0) + 1
            counters[spec.activity] = number
            return "r2-\(r2Slug(spec.activity))-\(number < 10 ? "0" : "")\(number)"
        }
        return r2Specs.indices.map { index in
            let spec = r2Specs[index]
            let same = r2Specs.indices.filter { r2Specs[$0].activity == spec.activity }
            let position = same.firstIndex(of: index) ?? 0
            let transfer = same[(position + 1) % same.count]
            return r2Item(spec, id: ids[index], transferId: ids[transfer], position: position)
        }
    }()

    static func r2Slug(_ activity: ReadingR2Activity) -> String {
        switch activity {
        case .decodeReveal: return "reveal"
        case .changeGrapheme: return "change"
        case .buildWord: return "build"
        }
    }

    private static func r2Item(_ spec: ReadingR2Spec, id: String, transferId: String, position: Int) -> ReadingBankItem {
        let word = spec.words[0]
        var palette = spec.palette
        if spec.activity == .decodeReveal, !palette.isEmpty {
            palette = Array(palette[(position % palette.count)...] + palette[..<(position % palette.count)])
        }
        var item = ReadingBankItem(
            id: id, rung: .r2, status: .approved, activity: .blendNew, grapheme: nil,
            tokens: word.map { String($0) }, palette: palette, words: spec.words,
            speechItem: ReadingItem(kind: word.count > 2 ? .word : .syllable, text: word),
            misconceptionCheck: r2Misconception(spec), independentAnswer: spec.activity == .buildWord ? .kit : .tap,
            workedHintKey: "reading.hint.r2." + id, transferId: transferId, needsSound: false)
        item.r2Activity = spec.activity
        item.pictureKey = spec.picture
        return item
    }

    private static func r2Misconception(_ spec: ReadingR2Spec) -> String {
        let word = spec.words[0]
        switch spec.activity {
        case .decodeReveal:
            return "Devine-t-il « \(word) » d'après l'image ou les premières lettres au lieu de lire toutes les lettres ?"
        case .changeGrapheme:
            return "Change-t-il plus d'une lettre de « \(word) » pour faire « \(spec.words[1]) » ?"
        case .buildWord:
            return "Place-t-il les lettres de « \(word) » dans le désordre ou prend-il une lettre en trop ?"
        }
    }
}
