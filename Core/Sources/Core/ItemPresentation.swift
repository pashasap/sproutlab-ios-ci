import Foundation

extension Item {
    /// The identity of this question's type; the level tile shows the same one.
    public var identity: ActivityIdentity {
        if isNotice { return .listenSound }
        if let id = readingId, let bank = ReadingBank.item(id: id) { return ActivityIdentity.reading(bank) }
        if readingId != nil { return .listenSound }
        switch kind {
        case .counting: return .counting
        case .bond: return .makeTen
        case .addition: return .plus
        case .subtraction: return .subtraction
        case .pattern: return .patterns
        case .comparison: return .comparison
        }
    }

    /// The prompt split into plain text and the highlighted keyword.
    public func promptSegments(_ language: Language) -> [PromptSegment] {
        identity.segments(forKey: promptKey, language)
    }

    /// Text-table key of the hint shown after a wrong answer.
    public var hintKey: String {
        if readingId != nil || isNotice { return "reading.help.r1.look" }
        switch kind {
        case .counting: return "round.look-at-dots"
        case .bond: return "round.count-empty"
        case .addition: return "round.hint.add"
        case .subtraction: return "round.hint.subtract"
        case .pattern: return "round.hint.pattern"
        case .comparison: return "round.hint.compare"
        }
    }

    /// The stimulus written out in words and numbers, for reading aloud and for screen readers.
    public func textEquivalent(_ language: Language) -> String {
        if detail == .plain {
            return TextTable.string(kind == .bond ? "round.prompt.bond" : "round.prompt.count", language)
        }
        return stimulus.textEquivalent(language)
    }

    /// What the ear button speaks: the question, then the stimulus in words.
    public func speechLine(_ language: Language) -> String {
        guard !isNotice else { return TextTable.string(promptKey, language) }
        let speechKey = promptKey.replacingOccurrences(of: ".prompt.", with: ".speech.")
        var line = TextTable.string(speechKey, language)
        if readingId != nil, detail != .plain { line += " " + textEquivalent(language) }
        if let spoken = SpokenMath.operation(detail, language) ?? SpokenMath.track(detail, language) {
            line += " " + spoken
        }
        // Put in order: Tap to Hear says the target word, so the child has something to listen to.
        if let id = readingId, let bank = ReadingBank.item(id: id), bank.activity == .sequenceSounds, bank.rung == .r1 {
            line += " " + bank.speechItem.text
        }
        return line
    }
}

extension ActivityIdentity {
    /// The identity of one authored reading item.
    static func reading(_ bank: ReadingBankItem) -> ActivityIdentity {
        if let activity = bank.r2Activity {
            switch activity {
            case .decodeReveal: return .readWord
            case .changeGrapheme: return .changeLetter
            case .buildWord: return .buildSyllable
            }
        }
        if let activity = bank.r3Activity {
            switch activity {
            case .selectDigraph: return .findPair
            case .blendWord: return .blendWord
            case .repairSplit: return .repairWord
            }
        }
        switch bank.activity {
        case .tapGrapheme: return .listenSound
        case .sequenceSounds: return .orderSounds
        case .blendNew: return .blendSounds
        }
    }
}

public struct ReadingChoicePresentation: Sendable, Equatable {
    public let text: String
    public let accessibilityLabel: String
}

public struct ReadingTilePresentation: Sendable, Equatable {
    public let text: String
    public let positionLabel: String
}

/// What a reading question shows: never a dot stimulus, never numeric answers.
public struct ReadingItemPresentation: Sendable, Equatable {
    public let dotStimulusCount: Int
    public let choices: [ReadingChoicePresentation]
    public let orderingTiles: [ReadingTilePresentation]
    public let slotCount: Int
    public let boardTiles: [String]
    public var stimulusWord: String = ""
    /// English prompt of an English reading item; empty for the French bank.
    public var promptText: String = ""
    public var slotLabels: [String] = []
    public var digraphTiles: [String] = []
    /// The full prompt of the item, never shortened; wraps over several lines in the view.
    public var instruction: String = ""
    /// What the child can do on the kit, in one full sentence.
    public var actionHint: String = ""
}

extension ReadingItemPresentation {
    /// The word or grapheme shown above the choices and tiles; a repaired split shows its letters apart.
    static func stimulus(_ bank: ReadingBankItem) -> String {
        let word = bank.words.first ?? bank.grapheme ?? ""
        guard bank.r3Activity == .repairSplit, let grapheme = bank.grapheme else { return word }
        let spaced = grapheme.map { String($0) }.joined(separator: " ")
        return word.replacingOccurrences(of: grapheme, with: spaced)
    }

    mutating func fillPrompt(of item: Item, _ language: Language) {
        instruction = TextTable.string(item.promptKey, language)
        actionHint = TextTable.string(Self.hintKey(kit: ReadingKitSession.make(for: item)), language)
    }

    static func hintKey(kit: ReadingKitSession?) -> String {
        switch kit?.state {
        case .sorting?: return "kit.hint.sorting"
        case .ordering?: return "kit.hint.ordering"
        case .board?: return "kit.hint.board"
        case .reveal?: return "kit.hint.reveal"
        default: return "kit.hint.tiles"
        }
    }

    static func slotLabels(count: Int, _ language: Language) -> [String] {
        let template = TextTable.string("reading.slot.empty", language)
        return (0..<count).map { template.replacingOccurrences(of: "%1", with: String($0 + 1)) }
    }
}

extension Item {
    /// Presentation data of a reading question; nil for math items and notices.
    public func readingPresentation(_ language: Language) -> ReadingItemPresentation? {
        if !isNotice, let id = readingId, let english = ReadingENBank.item(id: id) {
            return englishReadingPresentation(english, language)
        }
        guard !isNotice, let id = readingId, let bank = ReadingBank.item(id: id) else { return nil }
        var choices: [ReadingChoicePresentation] = []
        var tiles: [ReadingTilePresentation] = []
        var slotCount = 0
        var boardTiles: [String] = []
        if bank.rung == .r1, bank.activity == .tapGrapheme, let grapheme = bank.grapheme {
            var others = bank.palette.filter { $0 != grapheme }
            var texts: [String] = []
            for index in 0..<bank.palette.count {
                texts.append(index == correctIndex || others.isEmpty ? grapheme : others.removeFirst())
            }
            let word = TextTable.string("reading.choice.label", language)
            choices = texts.map { ReadingChoicePresentation(text: $0, accessibilityLabel: word + " " + $0) }
        }
        let changeWords = changeLetterWords()
        if !changeWords.isEmpty {
            let word = TextTable.string("reading.choice.label", language)
            choices = changeWords.map { ReadingChoicePresentation(text: $0, accessibilityLabel: word + " " + $0) }
        }
        switch ReadingKitSession.make(for: self)?.state {
        case .board(let board)?:
            slotCount = board.slots.count
            boardTiles = board.palette
        case .tiles(let set)?:
            boardTiles = set.tiles
        case .ordering(let ordering)?:
            let total = ordering.order.count
            let template = TextTable.string("reading.tile.position", language)
            tiles = ordering.order.enumerated().map { index, text in
                let label = template.replacingOccurrences(of: "%1", with: String(index + 1))
                    .replacingOccurrences(of: "%2", with: String(total))
                return ReadingTilePresentation(text: text, positionLabel: label)
            }
        default:
            break
        }
        var result = ReadingItemPresentation(dotStimulusCount: 0, choices: choices, orderingTiles: tiles,
                                             slotCount: slotCount, boardTiles: boardTiles)
        result.stimulusWord = ReadingItemPresentation.stimulus(bank)
        result.slotLabels = ReadingItemPresentation.slotLabels(count: slotCount, language)
        result.fillPrompt(of: self, language)
        if bank.r3Activity == .selectDigraph || bank.r3Activity == .repairSplit {
            result.digraphTiles = (bank.grapheme ?? "").map { String($0) }
        }
        return result
    }
}
