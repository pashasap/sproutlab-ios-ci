/// Which languages have a reading level; the English bank is not authored yet.
enum ReadingLanguages {
    static func hasReadingLevel(_ language: Language) -> Bool {
        switch language {
        case .fr: return true
        case .en: return false
        }
    }
}

extension Item {
    static let noLevelNoticeKey = "reading.notice.noLevel"

    /// An icon-led notice in place of `item`: it keeps the slot's role, shows the book icon, and any tap answers it.
    static func notice(replacing item: Item) -> Item {
        var out = Item(kind: .counting, operand: 1, choices: [1, 2, 3], correctIndex: 0)
        out.iconKey = "icon.readingFR"
        out.isNotice = true
        out.noticeTextKey = Item.noLevelNoticeKey
        out.configuration = item.configuration
        return out.placed(at: item.role == .familiar ? 1 : (item.isUnfamiliarTransfer ? 5 : 2), of: 5)
    }
}

extension TextTable {
    static let readingR3Texts: [String: TextEntry] = {
        var texts: [String: TextEntry] = [
            ReadingR3HelpLadder.keys[0]: TextEntry("Relie les deux lettres avec une accolade : elles vont ensemble.",
                                                   "Join the two letters with a bracket: they go together."),
            ReadingR3HelpLadder.keys[1]: TextEntry("Regarde les cases des sons : un groupe de lettres prend une seule case.",
                                                   "Look at the sound boxes: a group of letters takes just one box."),
            ReadingR3HelpLadder.keys[2]: TextEntry("Regarde le groupe de lettres lu comme un seul son, puis lis le mot.",
                                                   "Watch the letter group read as one sound, then read the word."),
            Item.noLevelNoticeKey: TextEntry("Pas encore de lecture dans cette langue. Touche pour continuer.",
                                             "No reading in this language yet. Tap to continue."),
            Item.noLevelNoticeKey + ".keyword": TextEntry("lecture", "reading")
        ]
        for item in ReadingBank.r3Items { texts[item.workedHintKey] = workedHintR3(item) }
        return texts
    }()

    private static func workedHintR3(_ item: ReadingBankItem) -> TextEntry {
        let word = item.words[0]
        let unit = item.grapheme ?? ""
        switch item.r3Activity {
        case .selectDigraph, .none:
            return TextEntry("Exemple : dans « \(word) », « \(unit) » est un seul groupe. Touche-le.",
                             "Example: in “\(word)”, “\(unit)” is one group. Tap it.")
        case .blendWord:
            return TextEntry("Exemple : « \(unit) » reste ensemble, puis on lit « \(word) » en entier.",
                             "Example: “\(unit)” stays together, then read all of “\(word)”.")
        case .repairSplit:
            return TextEntry("Exemple : dans « \(word) », les lettres « \(unit) » se rejoignent en un seul bloc.",
                             "Example: in “\(word)”, the letters “\(unit)” join back into one block.")
        }
    }
}
