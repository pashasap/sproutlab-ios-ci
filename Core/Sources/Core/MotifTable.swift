import Foundation

/// One short motif for the celebration and one per garden resident, all on the shared WarmTimbre.
/// Each is a plain `.motif` of timed `.note` events; the renderer turns it into samples.
public enum MotifTable {
    /// A motif's notes: frequency in Hz and start beat (100 bpm, so one beat is 0.6 s).
    private struct Spec {
        let frequencies: [Double]
        let beats: [Double]
    }

    public static let celebration: SoundRecipe = recipe(
        Spec(frequencies: [523.25, 659.25, 783.99, 1046.50, 1318.51],
             beats: [0, 0.3, 0.6, 0.9, 1.3]))

    /// Keyed by the garden resident ids (the same ids as `Collectible.table` and `GardenScene.garden.spots`).
    public static let residentMotifs: [String: SoundRecipe] = specs.mapValues { recipe($0) }

    private static let specs: [String: Spec] = [
        "sunflower": Spec(frequencies: [659.25, 783.99, 880.0], beats: [0, 0.5, 1.0]),
        "earthworm": Spec(frequencies: [329.63, 293.66], beats: [0, 0.7]),
        "ant": Spec(frequencies: [880.0, 987.77, 880.0, 987.77], beats: [0, 0.2, 0.4, 0.6]),
        "fern": Spec(frequencies: [392.0, 440.0, 523.25], beats: [0, 0.6, 1.2]),
        "ladybug": Spec(frequencies: [1046.50, 783.99, 1174.66], beats: [0, 0.25, 0.5]),
        "tree-frog": Spec(frequencies: [293.66, 440.0, 293.66], beats: [0, 0.4, 0.8]),
        "glowing-mushroom": Spec(frequencies: [587.33, 698.46, 880.0, 698.46], beats: [0, 0.35, 0.7, 1.4]),
        "axolotl": Spec(frequencies: [392.0, 523.25, 659.25, 523.25, 392.0], beats: [0, 0.45, 0.9, 1.35, 1.8]),
        "butterfly": Spec(frequencies: [1174.66, 1318.51, 1567.98], beats: [0, 0.15, 0.3]),
        "honeybee": Spec(frequencies: [880.0, 987.77, 880.0, 783.99], beats: [0, 0.15, 0.3, 0.45]),
        "snail": Spec(frequencies: [261.63, 293.66], beats: [0, 0.8]),
        "poppy": Spec(frequencies: [523.25, 659.25, 783.99], beats: [0, 0.4, 0.8]),
        "dandelion": Spec(frequencies: [698.46, 880.0, 1046.50], beats: [0, 0.3, 0.6]),
        "robin": Spec(frequencies: [1318.51, 1174.66, 1318.51, 1567.98], beats: [0, 0.2, 0.4, 0.7]),
        "cricket": Spec(frequencies: [1567.98, 1567.98, 1567.98], beats: [0, 0.1, 0.2])
    ]

    private static func recipe(_ spec: Spec) -> SoundRecipe {
        let events = zip(spec.frequencies, spec.beats).map { frequency, beat in
            SoundEvent(beat: beat, durationBeats: 1.0, recipe: .note(frequency: frequency, seconds: 0.6))
        }
        return .motif(events)
    }
}
