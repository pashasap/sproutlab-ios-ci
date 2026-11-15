/// SplitMix64 deterministic generator.
public struct SeededRandom: Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform-enough integer in 0..<bound (bound > 0).
    public mutating func below(_ bound: Int) -> Int {
        Int(next() % UInt64(max(bound, 1)))
    }

    public mutating func shuffled<T>(_ values: [T]) -> [T] {
        var out = values
        var i = out.count - 1
        while i > 0 {
            out.swapAt(i, below(i + 1))
            i -= 1
        }
        return out
    }
}
