import Foundation

/// Pure, deterministic background music: renders the `SongRecipe` loop, no files.
public enum MusicRenderer {
    static let peak = 0.33
    static let silentSeconds = 0.03
    static let fadeSeconds = 0.15

    /// Sample grid of the song.
    struct Grid {
        let rate: Int
        var samplesPerBeat: Double { Double(rate) * 60.0 / Double(SongRecipe.bpm) }
        var totalBeats: Int { SongRecipe.bars * SongRecipe.beatsPerBar }
        var total: Int { Int((Double(totalBeats) * samplesPerBeat).rounded()) }

        func start(ofBeat beat: Double) -> Int { Int((beat * samplesPerBeat).rounded()) }
        func seconds(ofBeats beats: Double) -> Double { beats * samplesPerBeat / Double(rate) }
    }

    public static func render(sampleRate: Int) -> [Float] {
        let grid = Grid(rate: max(sampleRate, 1))
        var buffer = [Double](repeating: 0, count: grid.total)
        addMelody(grid, into: &buffer)
        addPadAndBass(grid, into: &buffer)
        addDrums(grid, into: &buffer)
        return seal(buffer, rate: grid.rate)
    }

    // MARK: layers

    private static func addMelody(_ grid: Grid, into buffer: inout [Double]) {
        for note in SongRecipe.melody {
            let seconds = grid.seconds(ofBeats: note.durationBeats) + 0.15
            let tone = SoundRenderer.tone(note.frequency, seconds, grid.rate)
            place(tone, at: grid.start(ofBeat: note.beat), gain: 1.0, into: &buffer)
        }
    }

    private static func addPadAndBass(_ grid: Grid, into buffer: inout [Double]) {
        for (bar, chord) in SongRecipe.progression.enumerated() {
            let barBeat = Double(bar * SongRecipe.beatsPerBar)
            let length = grid.start(ofBeat: Double(SongRecipe.beatsPerBar))
            for frequency in chord.pad {
                let pad = padVoice(frequency, count: length, rate: grid.rate)
                place(pad, at: grid.start(ofBeat: barBeat), gain: 0.1, into: &buffer)
            }
            for offset in [0.0, 2.0] {
                let bass = SoundRenderer.tone(chord.bassRoot, grid.seconds(ofBeats: 1.5), grid.rate)
                place(bass, at: grid.start(ofBeat: barBeat + offset), gain: 0.6, into: &buffer)
            }
        }
    }

    private static func addDrums(_ grid: Grid, into buffer: inout [Double]) {
        let tick = SoundRenderer.noise(seconds: 0.04, decay: 70, smoothing: 0.3, rate: grid.rate)
        for beat in 0..<grid.totalBeats {
            place(tick, at: grid.start(ofBeat: Double(beat)), gain: 0.04, into: &buffer)
        }
    }

    /// A sustained sine with a slow sin^2 swell over one bar.
    private static func padVoice(_ frequency: Double, count: Int, rate: Int) -> [Float] {
        (0..<count).map { index in
            let t = Double(index) / Double(rate)
            let swell = pow(sin(Double.pi * Double(index) / Double(max(count, 1))), 2)
            return Float(swell * sin(2 * Double.pi * frequency * t))
        }
    }

    // MARK: mixing

    /// Adds `samples` at `start`, with a 15 ms release so a cut note never clicks.
    private static func place(_ samples: [Float], at start: Int, gain: Double, into buffer: inout [Double]) {
        let release = max(min(samples.count / 2, 330), 1)
        for (index, value) in samples.enumerated() where start + index < buffer.count {
            let tail = samples.count - index
            let ramp = tail >= release ? 1.0 : Double(tail) / Double(release)
            buffer[start + index] += Double(value) * gain * ramp
        }
    }

    /// Removes DC, holds the seam silent, fades in and out, then scales to the quiet peak.
    private static func seal(_ input: [Double], rate: Int) -> [Float] {
        guard !input.isEmpty else { return [] }
        let mean = input.reduce(0, +) / Double(input.count)
        let hold = Int(silentSeconds * Double(rate))
        let fade = max(Int(fadeSeconds * Double(rate)), 1)
        var out = input.enumerated().map { index, value -> Double in
            let edge = min(index, input.count - 1 - index)
            guard edge >= hold else { return 0 }
            let phase = min(Double(edge - hold) / Double(fade), 1)
            return (value - mean) * pow(sin(Double.pi / 2 * phase), 2)
        }
        let top = out.map { abs($0) }.max() ?? 0
        if top > 0 { out = out.map { $0 * peak / top } }
        return out.map { Float($0) }
    }
}
