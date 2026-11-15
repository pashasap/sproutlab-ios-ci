import Foundation

/// One melody note; `beat` is the start position in beats from the loop start.
public struct SongNote: Equatable, Sendable {
    public var frequency: Double
    public var beat: Double
    public var durationBeats: Double
}

/// The four chords of the song with their pad voicing and bass root.
enum SongChord: Equatable, Sendable {
    case c, f, g, am

    var pad: [Double] {
        switch self {
        case .c: return [261.63, 329.63, 392.00]
        case .f: return [261.63, 349.23, 440.00]
        case .g: return [246.94, 293.66, 392.00]
        case .am: return [261.63, 329.63, 440.00]
        }
    }

    var bassRoot: Double {
        switch self {
        case .c: return 130.81
        case .f: return 174.61
        case .g: return 196.00
        case .am: return 110.00
        }
    }
}

/// The 30 s A-B-A' song in C major: 12 bars of 4/4 at 96 bpm.
/// A is bars 1-4, B bars 5-8 and A' bars 9-12 (A with a different final bar).
public enum SongRecipe {
    public static let bpm = 96
    public static let bars = 12
    public static let beatsPerBar = 4

    /// C5 D5 E5 F5 G5 A5 B5 C6.
    static let scale: [Double] = [523.25, 587.33, 659.25, 698.46, 783.99, 880.00, 987.77, 1046.50]

    /// (scale degree, beat inside the section, length in beats).
    typealias Step = (degree: Int, beat: Double, length: Double)

    /// The hook: a stepwise five-note motif, E F G F E.
    static let hook: [Step] = [(2, 0, 1), (3, 1, 1), (4, 2, 1), (3, 3, 0.5), (2, 3.5, 0.5)]

    static let sectionA: [Step] = hook + [
        (4, 4, 1), (5, 5, 1), (4, 6, 1), (2, 7, 1),
        (2, 8, 1), (3, 9, 1), (4, 10, 1), (3, 11, 0.5), (2, 11.5, 0.5),
        (1, 12, 1), (2, 13, 1), (1, 14, 1), (0, 15, 1)
    ]

    static let sectionB: [Step] = [
        (7, 0, 1), (6, 1, 1), (5, 2, 1), (4, 3, 1),
        (5, 4, 2), (2, 6, 1), (4, 7, 1),
        (3, 8, 1), (5, 9, 1), (7, 10, 1), (5, 11, 1),
        (4, 12, 2), (1, 14, 2)
    ]

    /// The A' ending replaces the last bar of A with a rising close on C6.
    static let finalBar: [Step] = [(2, 12, 1), (4, 13, 1), (7, 14, 2)]

    static let sectionAPrime: [Step] = sectionA.filter { $0.beat < 12 } + finalBar

    public static let melody: [SongNote] =
        notes(sectionA, offset: 0) + notes(sectionB, offset: 16) + notes(sectionAPrime, offset: 32)

    static let progression: [SongChord] = [.c, .f, .g, .am, .am, .f, .c, .g, .c, .f, .g, .c]

    private static func notes(_ steps: [Step], offset: Double) -> [SongNote] {
        steps.map {
            SongNote(frequency: scale[$0.degree], beat: offset + $0.beat, durationBeats: $0.length)
        }
    }
}
