/// The three notes of the music track in pitch order: do, ré, mi (C, D, E).
public enum MusicNote: CaseIterable, Sendable, Equatable {
    case `do`, re, mi

    /// 0 (lowest) to 2 (highest).
    public var height: Int {
        switch self {
        case .do: return 0
        case .re: return 1
        case .mi: return 2
        }
    }

    public var solfege: String {
        switch self {
        case .do: return "do"
        case .re: return "ré"
        case .mi: return "mi"
        }
    }

    public var letter: String {
        switch self {
        case .do: return "C"
        case .re: return "D"
        case .mi: return "E"
        }
    }

    /// A different silhouette per note, so no question depends on colour alone.
    public var symbolName: String {
        switch self {
        case .do: return "circle"
        case .re: return "circle.fill"
        case .mi: return "star.fill"
        }
    }

    /// Solfège first; the letter is an optional parallel label, never the only cue.
    public func label(showLetters: Bool) -> String {
        showLetters ? "\(solfege) (\(letter))" : solfege
    }

    static func at(height: Int) -> MusicNote { allCases[min(max(height, 0), 2)] }
}

public enum MusicNotation {
    public static func keyLabels(showLetters: Bool) -> [String] {
        MusicNote.allCases.map { $0.label(showLetters: showLetters) }
    }
}

/// One event of a question: a symbol at a slot, whose height tells the note.
public struct MusicEvent: Equatable, Sendable {
    public let slot: Int
    public let note: MusicNote
    public let symbolName: String

    public init(slot: Int, note: MusicNote) {
        self.slot = slot
        self.note = note
        self.symbolName = note.symbolName
    }
}

public enum MusicA2Kind: CaseIterable, Sendable {
    case highLow, contour, beatPattern
}

public struct MusicA2Question: Equatable, Sendable {
    public let kind: MusicA2Kind
    public let events: [MusicEvent]
    public let choices: [[MusicEvent]]
    public let correctIndex: Int
    public let slotCount: Int
    public let configuration: Int
}

/// The finite domain of A2 questions: 2 high/low, 24 contours, 30 beat patterns.
enum MusicA2Domain {
    static let contours: [[Int]] = (0..<27).compactMap { code in
        let heights = [code / 9, (code / 3) % 3, code % 3]
        return Set(heights).count >= 2 ? heights : nil
    }

    static let slotSets: [[Int]] = [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3],
                                    [0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]]

    static let highLowCount = 2
    static let contourBase = 100
    static let beatBase = 300

    static var beatCount: Int { slotSets.count * 3 }

    static func slotCount(of kind: MusicA2Kind) -> Int {
        switch kind {
        case .highLow: return 1
        case .contour: return 3
        case .beatPattern: return 4
        }
    }

    static func configuration(_ kind: MusicA2Kind, _ index: Int) -> Int {
        switch kind {
        case .highLow: return index
        case .contour: return contourBase + index
        case .beatPattern: return beatBase + index
        }
    }

    static func events(_ kind: MusicA2Kind, _ index: Int) -> [MusicEvent] {
        switch kind {
        case .highLow:
            return [MusicEvent(slot: 0, note: .at(height: index == 0 ? 2 : 0))]
        case .contour:
            return contours[index].enumerated().map { MusicEvent(slot: $0.offset, note: .at(height: $0.element)) }
        case .beatPattern:
            let note = MusicNote.at(height: index % 3)
            return slotSets[index / 3].map { MusicEvent(slot: $0, note: note) }
        }
    }

    static func count(of kind: MusicA2Kind) -> Int {
        switch kind {
        case .highLow: return highLowCount
        case .contour: return contours.count
        case .beatPattern: return beatCount
        }
    }
}

public enum MusicA2Generator {
    static let roundKinds: [MusicA2Kind] = [.highLow, .contour, .beatPattern, .contour, .beatPattern]

    public static func questions(seed: UInt64) -> [MusicA2Question] {
        var rng = SeededRandom(seed: seed ^ 0x4D55_5349)
        return roundKinds.map { kind in
            question(kind, index: rng.below(MusicA2Domain.count(of: kind)), rng: &rng)
        }
    }

    /// Every question of the domain once, for exhaustive linting.
    static func allQuestions() -> [MusicA2Question] {
        var rng = SeededRandom(seed: 0x4D55)
        return MusicA2Kind.allCases.flatMap { kind in
            (0..<MusicA2Domain.count(of: kind)).map { question(kind, index: $0, rng: &rng) }
        }
    }

    static func question(_ kind: MusicA2Kind, index: Int, rng: inout SeededRandom) -> MusicA2Question {
        let events = MusicA2Domain.events(kind, index)
        let others = (0..<MusicA2Domain.count(of: kind)).filter { $0 != index }
        let wanted = kind == .highLow ? 1 : 2
        let wrong = rng.shuffled(others).prefix(wanted).map { MusicA2Domain.events(kind, $0) }
        let choices = rng.shuffled([events] + wrong)
        return MusicA2Question(kind: kind, events: events, choices: choices,
                               correctIndex: choices.firstIndex(of: events) ?? 0,
                               slotCount: MusicA2Domain.slotCount(of: kind),
                               configuration: MusicA2Domain.configuration(kind, index))
    }

    public static func items(seed: UInt64) -> [Item] {
        let list = questions(seed: seed)
        return list.enumerated().map { item(for: $0.element).placed(at: $0.offset + 1, of: list.count) }
    }

    static func configurations() -> [Item] {
        allQuestions().map { item(for: $0).placed(at: 2, of: 5) }
    }

    /// The round item of a question: the answer is the choice holding the value 1.
    static func item(for question: MusicA2Question) -> Item {
        var spare = [2, 3]
        let values = question.choices.indices.map { index -> Int in
            index == question.correctIndex ? 1 : spare.removeFirst()
        }
        var out = Item(kind: .counting, operand: 1, choices: values, correctIndex: question.correctIndex)
        out.iconKey = "icon.music"
        out.configuration = question.configuration
        return out
    }
}
