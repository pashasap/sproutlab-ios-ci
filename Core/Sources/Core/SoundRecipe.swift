import Foundation

/// A timed sound inside a motif or loop; positions are in beats.
public struct SoundEvent: Equatable, Sendable {
    public var beat: Double
    public var durationBeats: Double
    public var recipe: SoundRecipe

    public init(beat: Double, durationBeats: Double, recipe: SoundRecipe) {
        self.beat = beat
        self.durationBeats = durationBeats
        self.recipe = recipe
    }
}

/// A pure description of a sound; `SoundRenderer` turns it into samples.
public enum SoundRecipe: Equatable, Sendable {
    case note(frequency: Double, seconds: Double)
    case chord
    case bassNote
    case drumTick
    case noisePulse
    case motif([SoundEvent])
    case loop([[SoundEvent]])
}

/// The three mixer buses.
public enum AudioBus: Equatable, Sendable, CaseIterable {
    case music
    case effects
    case voice
}

/// Bus gains; the music bus is ducked while the voice is active.
public struct BusMixer: Equatable, Sendable {
    public static let duckedMusicGain: Float = 0.2

    public private(set) var voiceActive = false

    public init() {}

    public var musicGain: Float { voiceActive ? Self.duckedMusicGain : 1.0 }

    public func gain(for bus: AudioBus) -> Float {
        bus == .music ? musicGain : 1.0
    }

    public mutating func speechWillStart() { voiceActive = true }
    public mutating func speechDidEnd() { voiceActive = false }
}

/// A sound placed on the timeline in seconds.
public struct TimedSound: Equatable, Sendable {
    public var startSeconds: Double
    public var durationSeconds: Double
    public var recipe: SoundRecipe
}

public enum SoundScheduler {
    public static func schedule(events: [SoundEvent], bpm: Double) -> [TimedSound] {
        let secondsPerBeat = 60.0 / max(bpm, 1.0)
        return events.map {
            TimedSound(startSeconds: $0.beat * secondsPerBeat,
                       durationSeconds: $0.durationBeats * secondsPerBeat,
                       recipe: $0.recipe)
        }
    }
}
