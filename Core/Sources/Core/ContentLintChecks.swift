import Foundation

extension ContentLint {
    static let knownAccentWords = [
        "icon.math.label": "Mathématiques", "icon.hear.label": "Écouter",
        "icon.star.label": "Étoile", "icon.completed.label": "terminé",
        "icon.music.off.label": "coupée", "icon.lang.fr.label": "français"
    ]

    static func mergedTexts(_ tables: [ContentTextTable]) -> [String: TextEntry] {
        var texts: [String: TextEntry] = [:]
        for table in tables { texts.merge(table.entries) { first, _ in first } }
        return texts
    }

    static func tableFindings(_ registry: ContentRegistry) -> [ContentFinding] {
        var findings: [ContentFinding] = []
        var tables = Set<String>()
        var keys = Set<String>()
        for table in registry.tables {
            if !tables.insert(table.id).inserted {
                findings.append(ContentFinding(kind: "duplicate-table-id", subject: table.id))
            }
            for (key, entry) in table.entries {
                if !keys.insert(key).inserted {
                    findings.append(ContentFinding(kind: "duplicate-text-key", subject: key))
                }
                findings += textFindings(key, entry: entry)
            }
        }
        let texts = mergedTexts(registry.tables)
        for (key, word) in knownAccentWords where texts[key]?.fr.contains(word) != true {
            findings.append(ContentFinding(kind: "lost-accent", subject: key))
        }
        return findings
    }

    static func textFindings(_ key: String, entry: TextEntry) -> [ContentFinding] {
        var findings: [ContentFinding] = []
        if entry.fr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            findings.append(ContentFinding(kind: "missing-fr-key", subject: key))
        }
        if entry.en.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            findings.append(ContentFinding(kind: "missing-en-key", subject: key))
        }
        if key.hasPrefix("icon.") && !key.hasSuffix(".label") {
            if entry.fr != entry.en {
                findings.append(ContentFinding(kind: "symbol-locale-parity", subject: key))
            }
            for symbol in Set([entry.fr, entry.en]) where !ChromeCatalog.allSymbolNames.contains(symbol)
                && !ChromeCatalog.terrariumSymbolNames.contains(symbol) {
                findings.append(ContentFinding(kind: "unknown-symbol", subject: symbol))
            }
        }
        return findings
    }

    static func itemFindings(_ item: Item, level: LevelDefinition,
                             registry: ContentRegistry) -> [ContentFinding] {
        let subject = "\(level.levelId):\(item.kind.rawValue):\(item.configuration)"
        let before = ContentHelpState(item: item)
        let answer = DerivedAnswer.from(before.stimulus)
        var findings: [ContentFinding] = []
        if answer == nil || answer != item.answer || answer != before.correctOption {
            findings.append(ContentFinding(kind: "answer-not-derivable", subject: subject))
        }
        if answer == nil || item.choices.filter({ $0 == answer }).count != 1 {
            findings.append(ContentFinding(kind: "not-exactly-one-correct", subject: subject))
        }
        for language in Language.allCases {
            // Derivation is deliberately locale-independent; both locales draw these same positions.
            if DerivedAnswer.from(before.stimulus) != before.correctOption {
                findings.append(ContentFinding(kind: "answer-not-derivable", subject: subject))
            }
            for key in level.helpSteps {
                let step = registry.helpSteps[key] ?? .highlight
                let after = step.applying(to: before, language: language)
                if !keepsMeaning(before, after: after) {
                    findings.append(ContentFinding(kind: "help-changes-meaning", subject: subject + ":" + key))
                }
            }
        }
        return findings
    }

    /// A reading item has no dots to derive from: it must name an approved, decodable bank item.
    static func readingFindings(_ item: Item, level: LevelDefinition) -> [ContentFinding] {
        let subject = "\(level.levelId):\(item.readingId ?? "")"
        if let id = item.readingId, let sentence = FrenchSentenceBank.item(id: id) {
            let valid = item.choices.count == 3 && (0..<3).contains(item.correctIndex)
                && SentenceDecodability.check(sentence).isEmpty
            return valid ? [] : [ContentFinding(kind: "reading-item-invalid", subject: subject)]
        }
        if let id = item.readingId, let sentence = EnglishSentenceBank.item(id: id) {
            let valid = item.choices.count == 3 && (0..<3).contains(item.correctIndex)
                && SentenceDecodability.checkEnglish(sentence).isEmpty
            return valid ? [] : [ContentFinding(kind: "reading-item-invalid", subject: subject)]
        }
        if let id = item.readingId, let text = FrenchTextBank.item(id: id) {
            let valid = item.choices.count == 3 && (0..<3).contains(item.correctIndex)
                && ContentLint.textFindings(text).isEmpty
            return valid ? [] : [ContentFinding(kind: "reading-item-invalid", subject: subject)]
        }
        if let id = item.readingId, let text = EnglishTextBank.item(id: id) {
            let valid = item.choices.count == 3 && (0..<3).contains(item.correctIndex)
                && ContentLint.englishTextFindings(text).isEmpty
            return valid ? [] : [ContentFinding(kind: "reading-item-invalid", subject: subject)]
        }
        if let id = item.readingId, ReadingENBank.item(id: id) != nil {
            return item.choices.count == 3 && (0..<3).contains(item.correctIndex)
                ? [] : [ContentFinding(kind: "reading-item-invalid", subject: subject)]
        }
        guard let id = item.readingId, let bank = ReadingBank.item(id: id), bank.status == .approved,
              item.choices.count == 3, (0..<3).contains(item.correctIndex) else {
            return [ContentFinding(kind: "reading-item-invalid", subject: subject)]
        }
        let rung = bank.rung
        let bad = bank.words.contains { Decodability.check(word: $0, rung: rung) != .ok }
        return bad ? [ContentFinding(kind: "reading-word-undecodable", subject: subject)] : []
    }

    static func keepsMeaning(_ before: ContentHelpState, after: ContentHelpState) -> Bool {
        StimulusMeaning(before.stimulus) == StimulusMeaning(after.stimulus)
            && DerivedAnswer.from(before.stimulus) == DerivedAnswer.from(after.stimulus)
            && before.correctOption == after.correctOption
            && before.promptKey == after.promptKey
    }
}
