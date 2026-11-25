import Observation

public enum MusicA2HelpKind: Sendable, Equatable {
    case noteHeights, eventToSlot, demonstration
}

public struct MusicA2HelpStep: Equatable, Sendable {
    public let kind: MusicA2HelpKind
    public let text: String
    public let showsNoteHeights: Bool
    public let highlightedSlots: [Int]
}

/// Three rungs: note-height positions, then event-to-slot mapping, then one demonstrated event.
public enum MusicA2HelpLadder {
    static let keys = ["music.a2.help.heights", "music.a2.help.slots", "music.a2.help.demo"]

    public static func steps(for question: MusicA2Question, language: Language) -> [MusicA2HelpStep] {
        let slots = question.events.map { $0.slot }
        let text = keys.map { TextTable.string($0, language) }
        return [
            MusicA2HelpStep(kind: .noteHeights, text: text[0], showsNoteHeights: true, highlightedSlots: []),
            MusicA2HelpStep(kind: .eventToSlot, text: text[1], showsNoteHeights: false, highlightedSlots: slots),
            MusicA2HelpStep(kind: .demonstration, text: text[2], showsNoteHeights: false,
                            highlightedSlots: Array(slots.prefix(1)))
        ]
    }
}

extension MotifTable {
    /// Frequencies of do, ré, mi (C5, D5, E5), by note height.
    static let musicA2Frequencies = [523.25, 587.33, 659.25]

    /// One note per event, in slot order, one beat apart.
    public static func musicA2Motif(for events: [MusicEvent]) -> SoundRecipe {
        let sounds = events.sorted { $0.slot < $1.slot }.map { event in
            SoundEvent(beat: Double(event.slot), durationBeats: 1.0,
                       recipe: .note(frequency: musicA2Frequencies[event.note.height], seconds: 0.6))
        }
        return .motif(sounds)
    }
}

/// The audio boundary: the app plays a recipe, a fake records it in tests.
public protocol MusicEventPlayer: Sendable {
    func play(_ recipe: SoundRecipe) throws
}

public struct MusicA2PlaybackSettings: Sendable, Equatable {
    public let musicOn: Bool
    public let reduceMotion: Bool

    public init(musicOn: Bool, reduceMotion: Bool) {
        self.musicOn = musicOn
        self.reduceMotion = reduceMotion
    }
}

public enum MusicA2PlaybackOutcome: Sendable, Equatable {
    case idle, played, skippedMusicOff, skippedEngineUnavailable
}

/// Plays A2 events; a muted device, the music switch or an engine failure never changes usability.
@MainActor
@Observable
public final class MusicA2Playback {
    public private(set) var lastOutcome: MusicA2PlaybackOutcome = .idle
    public private(set) var showsEventPulse = false
    private let player: any MusicEventPlayer

    public init(player: any MusicEventPlayer) {
        self.player = player
    }

    public var isUsable: Bool { true }
    public var errorText: String? { nil }

    public func play(events: [MusicEvent], settings: MusicA2PlaybackSettings) {
        showsEventPulse = false
        guard settings.musicOn else {
            lastOutcome = .skippedMusicOff
            return
        }
        do {
            try player.play(MotifTable.musicA2Motif(for: events))
            lastOutcome = .played
            showsEventPulse = !settings.reduceMotion
        } catch {
            lastOutcome = .skippedEngineUnavailable
        }
    }
}

extension Curriculum {
    static let musicLevels: [LevelDefinition] = [
        LevelDefinition(
            levelId: "music-a2", strand: "music", titleKey: "trail.level.music-a2.title",
            activity: LevelActivity(
                type: "music-a2", generator: { MusicA2Generator.items(seed: $0) },
                helpSteps: MusicA2HelpLadder.keys, prerequisites: []
            ).enumerating { MusicA2Generator.configurations() }
        ).coded("A2"),
        musicA4Level
    ]

    static let musicTitleKeys = ["trail.level.music-a2.title", MusicA4.titleKey]
}

extension TextTable {
    static let musicTexts: [String: TextEntry] = [
        "track.music.name": TextEntry("Musique", "Music"),
        "trail.level.music-a2.title": TextEntry("Rythme, hauteur", "Beat & Pitch"),
        "music.a2.help.heights": TextEntry("Haut ou bas : do est en bas, mi est en haut.",
                                           "High or low: do is low, mi is high."),
        "music.a2.help.slots": TextEntry("Chaque signe va dans sa case, de gauche à droite.",
                                         "Each sign sits in its own slot, left to right."),
        "music.a2.help.demo": TextEntry("Regarde un signe : sa case et sa hauteur donnent la note.",
                                        "Watch one sign: its slot and height give the note.")
    ]
}
