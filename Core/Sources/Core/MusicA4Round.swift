/// One slot as the A4 screen shows it: its beat (nil when empty) and its SF Symbol name.
public struct MusicA4SlotPresentation: Equatable, Sendable {
    public let beat: MusicBeat?
    public let symbolName: String
    public let accessibilityLabel: String
}

public struct MusicA4Presentation: Equatable, Sendable {
    public let slots: [MusicA4SlotPresentation]
    public let paletteSymbols: [String]
    public let accessibilityLabels: [String]
}

/// The state of one A4 round: a seeded example pattern, palette editing and expansion.
public struct MusicA4Round: Equatable, Sendable {
    public private(set) var slots: [MusicBeat?]
    public private(set) var selected: MusicBeat?
    public private(set) var isPlaying = false

    public init(seed: UInt64) {
        slots = MusicA4Round.examplePattern(seed: seed).map { Optional($0) }
    }

    /// Four beats holding both drums and a rest, in a seeded order.
    static func examplePattern(seed: UInt64) -> [MusicBeat] {
        var rng = SeededRandom(seed: seed ^ 0xA4A4)
        var beats = MusicBeat.allCases
        beats.append(MusicBeat.allCases[rng.below(MusicBeat.allCases.count)])
        for index in stride(from: beats.count - 1, to: 0, by: -1) {
            beats.swapAt(index, rng.below(index + 1))
        }
        return Array(beats.prefix(MusicA4.slotCount))
    }

    public mutating func selectPalette(_ beat: MusicBeat) {
        selected = beat
    }

    public mutating func tapSlot(_ index: Int) {
        guard slots.indices.contains(index) else { return }
        if slots[index] != nil {
            slots[index] = nil
        } else if let beat = selected {
            slots[index] = beat
        }
    }

    public mutating func expand() {
        guard slots.count < MusicA4.expandedSlotCount else { return }
        slots += Array(repeating: nil, count: MusicA4.expandedSlotCount - slots.count)
    }

    /// The filled slots, in order, as a playable strip with the expanded or the base slot count.
    public var strip: GenericProgramStrip<MusicBeat> {
        var out = MusicA4.makeStrip(slotCount: slots.count)
        for beat in slots.compactMap({ $0 }) { out.add(beat) }
        return out
    }

    public func presentation(language: Language) -> MusicA4Presentation {
        let slotItems = slots.map { beat in
            MusicA4SlotPresentation(
                beat: beat, symbolName: beat?.symbolName ?? RobotText.emptySlotSymbol,
                accessibilityLabel: TextTable.string("music.a4.beat.\(beat?.rawValue ?? "empty")", language))
        }
        let palette = MusicBeat.allCases.map { TextTable.string("music.a4.beat.\($0.rawValue)", language) }
        let controls = ["music.a4.play", "music.a4.expand", "music.a4.save"].map { TextTable.string($0, language) }
        return MusicA4Presentation(
            slots: slotItems, paletteSymbols: MusicBeat.allCases.map(\.symbolName),
            accessibilityLabels: slotItems.map(\.accessibilityLabel) + palette + controls)
    }
}
