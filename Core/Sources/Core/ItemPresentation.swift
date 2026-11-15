extension Item {
    /// The identity of this question's type; the level tile shows the same one.
    public var identity: ActivityIdentity {
        if readingId != nil || isNotice { return .listenSound }
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
        let prompt = TextTable.string(promptKey, language)
        return detail == .plain ? prompt : prompt + " " + textEquivalent(language)
    }
}
