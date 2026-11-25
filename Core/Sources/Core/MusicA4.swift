/// The two drum timbres of level A4.
public enum MusicTimbre: String, CaseIterable, Codable, Sendable {
    case lowDrum, highDrum
}

/// One slot choice: a low sound, a high sound or a rest.
public enum MusicBeat: String, CaseIterable, Hashable, Sendable {
    case lowSound, highSound, rest

    public var isRest: Bool { self == .rest }

    public var timbre: MusicTimbre? {
        switch self {
        case .lowSound: return .lowDrum
        case .highSound: return .highDrum
        case .rest: return nil
        }
    }

    public var symbolName: String {
        switch self {
        case .lowSound: return "circle.fill"
        case .highSound: return "star.fill"
        case .rest: return "circle"
        }
    }
}

/// A symbolic event: its slot, its timbre and whether it is a rest. Never audio.
public struct MusicA4Event: Equatable, Codable, Sendable {
    public let slot: Int
    public let timbre: MusicTimbre
    public let isRest: Bool

    public init(slot: Int, timbre: MusicTimbre, isRest: Bool) {
        self.slot = slot
        self.timbre = timbre
        self.isRest = isRest
    }
}

public struct MusicA4Pattern: Equatable, Codable, Sendable {
    public let events: [MusicA4Event]

    public init(events: [MusicA4Event]) {
        self.events = events
    }
}

public enum MusicA4 {
    public static let levelId = "music-a4"
    public static let slotCount = 4
    public static let expandedSlotCount = 8

    public static func makeStrip(slotCount: Int) -> GenericProgramStrip<MusicBeat> {
        GenericProgramStrip<MusicBeat>(slotCount: slotCount, palette: MusicBeat.allCases)
    }

    /// An 8-slot strip that keeps the cards and repeat blocks already placed, in order.
    public static func expanding(_ strip: GenericProgramStrip<MusicBeat>) -> GenericProgramStrip<MusicBeat> {
        var out = makeStrip(slotCount: expandedSlotCount)
        let cards = strip.cards
        for index in 0...cards.count {
            for entry in strip.repeats where min(entry.after, cards.count) == index {
                out.addRepeat(entry.block)
            }
            if index < cards.count { out.add(cards[index]) }
        }
        return out
    }

    /// The timeline: the expanded strip with the slot index of each beat.
    public static func events(for strip: GenericProgramStrip<MusicBeat>) -> [MusicA4Event] {
        strip.expanded().enumerated().map { offset, beat in
            MusicA4Event(slot: offset, timbre: beat.timbre ?? .lowDrum, isRest: beat.isRest)
        }
    }

    public static func contrasts(_ answer: [MusicBeat], with call: [MusicBeat]) -> Bool {
        !call.isEmpty && answer.count == call.count && answer != call
    }

    /// One sound per non-rest event at its slot; the two timbres use different recipes.
    public static func motif(for events: [MusicA4Event]) -> SoundRecipe {
        let sounds = events.filter { !$0.isRest }.sorted { $0.slot < $1.slot }.map { event in
            SoundEvent(beat: Double(event.slot), durationBeats: 1.0,
                       recipe: event.timbre == .lowDrum ? .bassNote : .drumTick)
        }
        return .motif(sounds)
    }

    static let titleKey = "trail.level.music-a4.title"
    static let helpKeys = ["music.a4.help.events", "music.a4.help.groups", "music.a4.help.demo"]

    static func items(seed: UInt64) -> [Item] {
        var rng = SeededRandom(seed: seed ^ 0x4134)
        return (1...5).map { position in
            item(configuration: 6000 + rng.below(1000)).placed(at: position, of: 5)
        }
    }

    static func configurations() -> [Item] {
        (0..<5).map { item(configuration: 6000 + $0).placed(at: 2, of: 5) }
    }

    private static func item(configuration: Int) -> Item {
        var item = Item(kind: .counting, operand: 1, choices: [1, 2, 3], correctIndex: 0)
        item.robotId = "music.A4"
        item.iconKey = "icon.music"
        item.configuration = configuration
        return item
    }
}

public enum MusicA4HelpKind: Sendable, Equatable {
    case eventSymbols, groupedRepeats, demonstration
}

public struct MusicA4HelpStep: Equatable, Sendable {
    public let kind: MusicA4HelpKind
    public let text: String
    public let symbolNames: [String]
    public let groupedUnits: [[String]]
    public let isEditable: Bool
    public let pattern: [MusicBeat]
}

/// Three rungs: event symbols, then grouped repeated units, then one editable demonstration.
public enum MusicA4HelpLadder {
    public static func steps(language: Language) -> [MusicA4HelpStep] {
        let text = MusicA4.helpKeys.map { TextTable.string($0, language) }
        let demo: [MusicBeat] = [.lowSound, .rest, .highSound, .rest]
        return [
            MusicA4HelpStep(kind: .eventSymbols, text: text[0], symbolNames: MusicBeat.allCases.map(\.symbolName),
                            groupedUnits: [], isEditable: false, pattern: []),
            MusicA4HelpStep(kind: .groupedRepeats, text: text[1], symbolNames: [],
                            groupedUnits: [[MusicBeat.lowSound.symbolName],
                                           [MusicBeat.highSound.symbolName, MusicBeat.rest.symbolName]],
                            isEditable: false, pattern: []),
            MusicA4HelpStep(kind: .demonstration, text: text[2], symbolNames: demo.map(\.symbolName),
                            groupedUnits: [], isEditable: true, pattern: demo)
        ]
    }
}

extension Curriculum {
    static let musicA4Level = LevelDefinition(
        levelId: MusicA4.levelId, strand: "music", titleKey: MusicA4.titleKey,
        activity: LevelActivity(
            type: MusicA4.levelId, generator: { MusicA4.items(seed: $0) },
            helpSteps: MusicA4.helpKeys, prerequisites: ["music-a2"]
        ).enumerating { MusicA4.configurations() }
    ).coded("A4")
}

extension TextTable {
    static let musicA4Texts: [String: TextEntry] = [
        MusicA4.titleKey: TextEntry("Mon rythme", "My Rhythm"),
        "music.a4.help.events": TextEntry("Un rond, une étoile ou une pause : choisis pour chaque case.",
                                           "A dot, a star or a pause: pick one for each slot."),
        "music.a4.help.groups": TextEntry("Un petit groupe peut se répéter : regarde-le.",
                                          "A small group can repeat: look at it."),
        "music.a4.help.demo": TextEntry("Voici un rythme : change-le comme tu veux.",
                                        "Here is a rhythm: change it as you like."),
        "music.a4.beat.lowSound": TextEntry("Son grave", "Low sound"),
        "music.a4.beat.highSound": TextEntry("Son aigu", "High sound"),
        "music.a4.beat.rest": TextEntry("Silence", "Rest"),
        "music.a4.beat.empty": TextEntry("Case vide", "Empty slot"),
        "music.a4.play": TextEntry("Écouter", "Play"),
        "music.a4.expand": TextEntry("Huit cases", "Eight slots"),
        "music.a4.save": TextEntry("Garder", "Keep")
    ]
}
