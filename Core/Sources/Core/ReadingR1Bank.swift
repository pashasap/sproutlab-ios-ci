public enum ReadingItemStatus: Equatable, Sendable {
    case approved, draft
}

public enum ReadingR1Activity: CaseIterable, Equatable, Sendable {
    case tapGrapheme, sequenceSounds, blendNew
}

/// One authored R1 item: what to tap or build, how it is spoken, and its checks and help.
public struct ReadingBankItem: Equatable, Sendable {
    public let id: String
    public let rung: ReadingRung
    public let status: ReadingItemStatus
    public let activity: ReadingR1Activity
    /// Tap activity only: the grapheme to tap.
    public let grapheme: String?
    /// Sequence and blend: the sound tokens in answer order; empty for tap.
    public let tokens: [String]
    public let palette: [String]
    public let words: [String]
    /// The modelled sound: a syllable or a word, never a bare phoneme.
    public let speechItem: ReadingItem
    public let misconceptionCheck: String
    public let independentAnswer: AnswerSource
    public let workedHintKey: String
    public let transferId: String
    public let needsSound: Bool
    /// R2 only: the activity of this item; nil for R1 items.
    public internal(set) var r2Activity: ReadingR2Activity? = nil
    /// R2 reveal items only: the id of the reading recipe shown after the correct answer.
    public internal(set) var pictureKey: String? = nil
    /// R3 only: the activity of this item; nil for R1 and R2 items.
    public internal(set) var r3Activity: ReadingR3Activity? = nil
}

/// The authored data of one R1 item before ids, checks and hint keys are derived.
struct ReadingR1Spec {
    let activity: ReadingR1Activity
    let grapheme: String?
    let tokens: [String]
    let palette: [String]
    let text: String
}

extension ReadingBank {
    public static func items(rung: ReadingRung) -> [ReadingBankItem] {
        switch rung {
        case .r1: return r1Items
        case .r2: return r2Items
        case .r3: return r3Items
        }
    }

    public static func item(id: String) -> ReadingBankItem? {
        r1Items.first { $0.id == id } ?? r2Items.first { $0.id == id } ?? r3Items.first { $0.id == id }
    }

    private static func tap(_ grapheme: String, _ palette: [String], _ text: String) -> ReadingR1Spec {
        ReadingR1Spec(activity: .tapGrapheme, grapheme: grapheme, tokens: [], palette: palette, text: text)
    }

    private static func build(_ activity: ReadingR1Activity, _ text: String, _ extra: String) -> ReadingR1Spec {
        let tokens = text.map { String($0) }
        return ReadingR1Spec(activity: activity, grapheme: nil, tokens: tokens,
                             palette: tokens + [extra], text: text)
    }

    static let r1Specs: [ReadingR1Spec] = [
        tap("a", ["a", "i", "o"], "ma"), tap("e", ["e", "u", "i"], "mer"), tap("i", ["i", "a", "u"], "si"),
        tap("o", ["o", "a", "e"], "ro"), tap("u", ["u", "o", "i"], "ru"), tap("m", ["m", "s", "f"], "ma"),
        tap("s", ["s", "f", "r"], "sa"), tap("f", ["f", "m", "r"], "fi"), tap("r", ["r", "s", "m"], "ro"),
        tap("a", ["a", "o", "e"], "sofa"), tap("m", ["m", "r", "f"], "mur"), tap("r", ["r", "s", "u"], "sur"),
        build(.sequenceSounds, "ma", "o"), build(.sequenceSounds, "mi", "u"), build(.sequenceSounds, "sa", "e"),
        build(.sequenceSounds, "si", "a"), build(.sequenceSounds, "fa", "o"), build(.sequenceSounds, "fi", "u"),
        build(.sequenceSounds, "ro", "a"), build(.sequenceSounds, "ru", "i"), build(.sequenceSounds, "mur", "s"),
        build(.sequenceSounds, "sur", "f"), build(.sequenceSounds, "mer", "i"), build(.sequenceSounds, "fer", "a"),
        build(.blendNew, "ra", "o"), build(.blendNew, "ri", "u"), build(.blendNew, "mo", "a"),
        build(.blendNew, "mu", "i"), build(.blendNew, "so", "e"), build(.blendNew, "su", "a"),
        build(.blendNew, "fo", "i"), build(.blendNew, "fu", "e"), build(.blendNew, "re", "o"),
        build(.blendNew, "me", "u"), build(.blendNew, "mas", "i"), build(.blendNew, "fus", "o")
    ]

    static let r1Items: [ReadingBankItem] = {
        var counters: [ReadingR1Activity: Int] = [:]
        let ids = r1Specs.map { spec -> String in
            let number = (counters[spec.activity] ?? 0) + 1
            counters[spec.activity] = number
            return "r1-\(r1Slug(spec.activity))-\(number < 10 ? "0" : "")\(number)"
        }
        return r1Specs.indices.map { index in
            let spec = r1Specs[index]
            let same = r1Specs.indices.filter { r1Specs[$0].activity == spec.activity }
            let position = same.firstIndex(of: index) ?? 0
            let transfer = same[(position + 1) % same.count]
            return r1Item(spec, id: ids[index], transferId: ids[transfer])
        }
    }()

    static func r1Slug(_ activity: ReadingR1Activity) -> String {
        switch activity {
        case .tapGrapheme: return "tap"
        case .sequenceSounds: return "seq"
        case .blendNew: return "blend"
        }
    }

    private static func r1Item(_ spec: ReadingR1Spec, id: String, transferId: String) -> ReadingBankItem {
        let isTap = spec.activity == .tapGrapheme
        return ReadingBankItem(
            id: id, rung: .r1, status: .approved, activity: spec.activity, grapheme: spec.grapheme,
            tokens: spec.tokens, palette: spec.palette, words: [spec.text],
            speechItem: ReadingItem(kind: spec.text.count > 2 ? .word : .syllable, text: spec.text),
            misconceptionCheck: r1Misconception(spec), independentAnswer: isTap ? .tap : .kit,
            workedHintKey: "reading.hint.r1." + id, transferId: transferId, needsSound: false)
    }

    private static func r1Misconception(_ spec: ReadingR1Spec) -> String {
        switch spec.activity {
        case .tapGrapheme:
            let other = spec.palette.first { $0 != spec.grapheme } ?? ""
            return "Confond-il « \(spec.grapheme ?? "") » avec « \(other) » dans « \(spec.text) » ?"
        case .sequenceSounds:
            return "Inverse-t-il l'ordre des sons de « \(spec.text) » ?"
        case .blendNew:
            return "Devine-t-il « \(spec.text) » au lieu d'enchaîner « \(spec.tokens.first ?? "") » puis la suite ?"
        }
    }
}
