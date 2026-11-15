import Foundation

/// The one timbre shared by every melodic sound: sine plus quiet harmonics,
/// soft attack, exponential decay and a gentle low-pass.
public struct WarmTimbre: Sendable {
    public var harmonics: [Double] = [1.0, 0.22, 0.08]
    public var attackSeconds = 0.012
    public var decayRate = 3.5
    public var lowPass = 0.45

    public init() {}
}

/// Pure, deterministic recipe renderer (no platform audio).
public enum SoundRenderer {
    static let peak: Float = 0.8
    static let fadeSeconds = 0.006
    static let motifBpm = 100.0
    static let chordFrequencies = [261.63, 329.63, 392.0]

    public static func render(_ recipe: SoundRecipe, sampleRate: Int) -> [Float] {
        let rate = max(sampleRate, 1)
        switch recipe {
        case let .note(frequency, seconds):
            return finish(tone(frequency, seconds, rate), rate)
        case .chord:
            let voices = chordFrequencies.map { tone($0, 0.8, rate) }
            return finish(mix(voices.map { ($0, 0) }), rate)
        case .bassNote:
            return finish(tone(110, 0.4, rate), rate)
        case .drumTick:
            return finish(noise(seconds: 0.06, decay: 60, smoothing: 0.0, rate: rate), rate)
        case .noisePulse:
            return finish(noise(seconds: 0.2, decay: 14, smoothing: 0.7, rate: rate), rate)
        case let .motif(events):
            return finish(motif(events, rate), rate)
        case let .loop(sections):
            return finish(sections.flatMap { motif($0, rate) }, rate)
        }
    }

    // MARK: voices

    static func tone(_ frequency: Double, _ seconds: Double, _ rate: Int) -> [Float] {
        let timbre = WarmTimbre()
        let count = max(Int((seconds * Double(rate)).rounded()), 0)
        var out = [Float](repeating: 0, count: count)
        var state = 0.0
        for index in 0..<count {
            let t = Double(index) / Double(rate)
            var value = 0.0
            for (order, level) in timbre.harmonics.enumerated() {
                value += level * sin(2 * Double.pi * frequency * Double(order + 1) * t)
            }
            let attack = min(t / timbre.attackSeconds, 1)
            let envelope = (0.5 - 0.5 * cos(Double.pi * attack)) * exp(-timbre.decayRate * t)
            state += timbre.lowPass * (value * envelope - state)
            out[index] = Float(state)
        }
        return out
    }

    /// Filtered noise from a fixed-seed generator, so it is deterministic.
    static func noise(seconds: Double, decay: Double, smoothing: Double, rate: Int) -> [Float] {
        let count = max(Int((seconds * Double(rate)).rounded()), 0)
        var generator = SplitMix(state: 0x5EED_50DA)
        var state = 0.0
        var out = [Float](repeating: 0, count: count)
        for index in 0..<count {
            let white = generator.nextUnit() * 2 - 1
            state = smoothing * state + (1 - smoothing) * white
            out[index] = Float(state * exp(-decay * Double(index) / Double(rate)))
        }
        return out
    }

    // MARK: composition

    static func motif(_ events: [SoundEvent], _ rate: Int) -> [Float] {
        let timed = SoundScheduler.schedule(events: events, bpm: motifBpm)
        let parts = timed.map { sound in
            (render(sound.recipe, sampleRate: rate), Int((sound.startSeconds * Double(rate)).rounded()))
        }
        return mix(parts)
    }

    static func mix(_ parts: [([Float], Int)]) -> [Float] {
        let length = parts.map { $0.1 + $0.0.count }.max() ?? 0
        var out = [Float](repeating: 0, count: length)
        for (samples, offset) in parts {
            for (index, value) in samples.enumerated() { out[offset + index] += value }
        }
        return out
    }

    // MARK: finishing

    /// Removes DC offset, fades both edges to silence and scales to a safe peak.
    static func finish(_ input: [Float], _ rate: Int) -> [Float] {
        guard !input.isEmpty else { return input }
        var out = input
        let mean = out.reduce(0.0) { $0 + Double($1) } / Double(out.count)
        for index in out.indices { out[index] -= Float(mean) }
        let fade = max(Int(fadeSeconds * Double(rate)), 1)
        for index in 0..<min(fade, out.count) {
            let gain = Float(index) / Float(fade)
            out[index] *= gain
            out[out.count - 1 - index] *= gain
        }
        let top = out.map { abs($0) }.max() ?? 0
        if top > 0 {
            let scale = peak / top
            for index in out.indices { out[index] *= scale }
        }
        return out
    }
}

/// Small deterministic generator for the noise recipes.
struct SplitMix {
    var state: UInt64

    mutating func nextUnit() -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) / Double(1 << 53)
    }
}
