import Foundation

/// What the journal view draws: the garden tab, one card per resident and the back control.
public struct JournalScreen: Equatable, Sendable {
    public static let closeIconKey = "icon.back"
    public static let closeLabelKey = "journal.close.label"

    public let title: String
    public let garden: JournalGarden
    public let cards: [JournalCard]
    public let closeControl: TerrariumControl

    public init(record: ProgressRecord, language: Language) {
        let model = JournalModel(record: record, language: language)
        title = model.title
        garden = model.garden
        cards = model.cards
        closeControl = TerrariumControl(accessibilityId: "sproutlab.journal.close",
                                        iconKey: Self.closeIconKey, labelKey: Self.closeLabelKey, side: 56)
    }

    /// The icon key drawn for an earned stamp (all from the icon table).
    public static func stampIconKey(_ stamp: Stamp) -> String {
        switch stamp {
        case .seenAtNight: return "icon.star"
        case .heard: return "icon.hear"
        case .counted: return "icon.counting"
        case .fed: return "icon.completed"
        }
    }

    public static func stampLabelKey(_ stamp: Stamp) -> String { stampIconKey(stamp) + ".label" }
}

/// The book icon in the chrome.
public struct JournalEntry: Equatable, Sendable {
    public let identifier: String
    public let accessibilityLabel: String
    public let minTarget: Double
    public let symbolName: String
}

extension ChromeCatalog {
    public static let journalIdentifier = "sproutlab.journal"
    public static let journalScreenIdentifier = journalIdentifier + ".screen"

    public static func journalEntry(language: Language) -> JournalEntry {
        JournalEntry(identifier: journalIdentifier,
                     accessibilityLabel: TextTable.string("icon.journal.label", language),
                     minTarget: ChromeIcon.minimumTarget, symbolName: journalSymbolName)
    }
}
