import Foundation

/// One short sound inside a resident call; times are in seconds.
struct CallNote: Equatable, Sendable {
    var at: Double
    var hertz: Double
    var length: Double
}

/// A call recipe for each resident, played only when the child taps a met resident.
public enum ResidentCalls {
    /// Effects-bus gain of every call: well below the voice gain.
    public static let gain: Float = 0.3

    private static let secondsPerBeat = 60.0 / SoundRenderer.motifBpm
    private static let silentTail = 0.3

    public static let recipes: [String: SoundRecipe] = notes.mapValues { recipe($0, tail: tail(of: $0)) }

    /// A single long hum keeps a short tail so the tone stays continuous; other calls get a longer one.
    private static func tail(of list: [CallNote]) -> Double {
        list.count == 1 && list[0].length > 0.8 ? 0.1 : silentTail
    }

    static func recipe(_ list: [CallNote], tail: Double) -> SoundRecipe {
        var events = list.map {
            SoundEvent(beat: $0.at / secondsPerBeat, durationBeats: $0.length / secondsPerBeat,
                       recipe: .note(frequency: $0.hertz, seconds: $0.length))
        }
        // A silent note after the last sound guarantees a silent end.
        let end = list.map { $0.at + $0.length }.max() ?? 0
        events.append(SoundEvent(beat: end / secondsPerBeat, durationBeats: tail / secondsPerBeat,
                                 recipe: .note(frequency: 0, seconds: tail)))
        return .motif(events)
    }

    private static func train(hertz: Double, count: Int, every: Double, length: Double) -> [CallNote] {
        (0..<count).map { CallNote(at: Double($0) * every, hertz: hertz, length: length) }
    }

    private static func melody(_ pitches: [Double], every: Double, length: Double) -> [CallNote] {
        pitches.enumerated().map { CallNote(at: Double($0.offset) * every, hertz: $0.element, length: length) }
    }

    static let notes: [String: [CallNote]] = [
        "sunflower": melody([392, 494], every: 0.3, length: 0.35),
        "earthworm": train(hertz: 130, count: 2, every: 0.5, length: 0.3),
        "ant": train(hertz: 880, count: 5, every: 0.1, length: 0.04),
        "fern": melody([300], every: 0.5, length: 0.6),
        "ladybug": melody([1000, 1200], every: 0.2, length: 0.08),
        "tree-frog": train(hertz: 400, count: 4, every: 0.24, length: 0.1),
        "glowing-mushroom": melody([523, 659], every: 0.3, length: 0.4),
        "axolotl": melody([330, 370, 415], every: 0.2, length: 0.12),
        "butterfly": melody([600, 720, 840], every: 0.15, length: 0.07),
        "honeybee": [CallNote(at: 0, hertz: 160, length: 0.9)],
        "snail": melody([200], every: 0.5, length: 0.6),
        "poppy": melody([440, 550], every: 0.25, length: 0.3),
        "dandelion": melody([700, 880], every: 0.25, length: 0.3),
        "robin": melody([660, 784, 880, 740, 988], every: 0.2, length: 0.18),
        "cricket": train(hertz: 2000, count: 8, every: 0.07, length: 0.03)
    ]
}
