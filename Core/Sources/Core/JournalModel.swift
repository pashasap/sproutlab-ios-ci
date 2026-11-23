import Foundation

public struct JournalEar: Equatable, Sendable {
    public let name: String
    public let fact: String
    public let control: TerrariumControl
}

public struct JournalCard: Equatable, Sendable {
    public let id: String
    public let state: CollectibleState
    public var silhouette = false
    public var arrivalIcon: String?
    public var trackIcon: String?
    public var milestoneStars: Int?
    public var starFallback: Int?
    public var placeholderWobble = false
    public var welcomeLabel: String?
    public var call: SoundRecipe?
    public var ear: JournalEar?
    public var callPlayLabel: String?
    public var stamps: [Stamp] = []

    init(id: String, state: CollectibleState) {
        self.id = id
        self.state = state
    }
}

public struct JournalGarden: Equatable, Sendable {
    public let habitatId: String
    /// One Bool per resident of the habitat, true once it has arrived. Shown without a number.
    public let pips: [Bool]
    public let pipsLabel: String
    public var total: Int { pips.count }
    public var filled: Int { pips.filter { $0 }.count }
}

public enum JournalPage: Equatable, Sendable {
    case garden(JournalGarden)
    case card(JournalCard)
}

public struct JournalModel: Equatable, Sendable {
    public static let maxStamps = 4
    public static let arrivalIconKey = "icon.star"

    public let title: String
    public let pages: [JournalPage]

    public var garden: JournalGarden {
        if case .garden(let garden)? = pages.first { return garden }
        return JournalGarden(habitatId: "", pips: [], pipsLabel: "")
    }

    public var cards: [JournalCard] {
        pages.compactMap { page in
            if case .card(let card) = page { return card }
            return nil
        }
    }

    public init(record: ProgressRecord, language: Language) {
        title = TextTable.string("journal.title", language)
        let cards = Collectible.table.map { Self.card($0, record: record, language: language) }
        pages = [.garden(Self.garden(record: record, language: language))] + cards.map { .card($0) }
    }

    private static func garden(record: ProgressRecord, language: Language) -> JournalGarden {
        let habitat = Collectible.table.first?.habitatId ?? "garden"
        let pips = Collectible.table.filter { $0.habitatId == habitat }.map {
            CollectionEvaluator.state(for: $0, record: record) != .notArrived
        }
        return JournalGarden(habitatId: habitat, pips: pips,
                             pipsLabel: TextTable.string("journal.pips", language))
    }

    private static func card(_ item: Collectible, record: ProgressRecord, language: Language) -> JournalCard {
        let state = CollectionEvaluator.state(for: item, record: record)
        var card = JournalCard(id: item.id, state: state)
        switch state {
        case .notArrived:
            card.silhouette = true
            card.arrivalIcon = arrivalIconKey
            switch item.rule {
            case .firstCompletion(let levelId, let fallback):
                card.trackIcon = trackIcon(levelId)
                card.starFallback = fallback
            default:
                card.milestoneStars = item.milestone
            }
        case .ready:
            card.placeholderWobble = true
            card.welcomeLabel = TextTable.string("journal.welcome", language)
        case .met:
            card.call = ResidentCalls.recipes[item.id]
            card.ear = JournalEar(
                name: item.name(language), fact: ResidentFacts.text(item.id, language),
                control: TerrariumControl(accessibilityId: "sproutlab.journal.ear." + item.id,
                                          iconKey: "icon.hear", labelKey: "icon.hear.label", side: 56))
            card.callPlayLabel = (language == .fr ? "Écouter le cri de " : "Listen to the call of ")
                + item.name(language)
            let earned = record.stamps[item.id] ?? ResidentStamps()
            card.stamps = Array(Stamp.allCases.filter { earned.has($0) }.prefix(maxStamps))
        }
        return card
    }

    private static func trackIcon(_ levelId: String) -> String {
        let track = LevelCatalog.standard.levels.first { $0.levelId == levelId }?.track
        return track == "music" ? "icon.music" : "icon.trail"
    }
}

extension TextTable {
    static let journalTexts: [String: TextEntry] = [
        "journal.title": TextEntry("Mon carnet de nature", "My nature journal"),
        "journal.welcome": TextEntry("Bienvenue", "Welcome"),
        "journal.close.label": TextEntry("Retour au terrarium", "Back to the terrarium"),
        "journal.pips": TextEntry("Habitants arrivés dans le jardin", "Residents who have arrived in the garden")
    ]
}
