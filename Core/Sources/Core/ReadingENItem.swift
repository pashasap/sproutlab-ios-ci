/// The three English reading rungs. Authored in English for a Grade 1 early reader; nothing is translated.
public enum ReadingENRung: String, CaseIterable, Sendable {
    case en1, en2, en3

    public var levelId: String { "reading-en-" + rawValue }
}

/// What a question asks the child to do.
public enum ReadingENActivity: String, Sendable {
    case graphemeSound, cvcSequence
    case readReveal, changeGrapheme, buildTiles
    case digraph, blend, repairSplit
}

/// What the child can see or hear when the question opens. A question must show something to read or pick.
public struct ReadingENStimulus: Equatable, Sendable {
    public let visibleGraphemes: [String]
    public let tileChoices: [String]
    public let speech: String

    public init(visibleGraphemes: [String], tileChoices: [String], speech: String) {
        self.visibleGraphemes = visibleGraphemes
        self.tileChoices = tileChoices
        self.speech = speech
    }
}

public struct ReadingENItem: Equatable, Sendable {
    public let id: String
    public let rung: ReadingENRung
    public let activity: ReadingENActivity
    /// Letters or letter groups, one per phoneme for EN1 and for blends.
    public internal(set) var graphemes: [String] = []
    public internal(set) var phonemes: [String] = []
    /// The word answers: one word, or two for change-one-grapheme and split repair.
    public internal(set) var words: [String] = []
    /// Tiles offered for a build round.
    public internal(set) var tiles: [String] = []
    /// Recipe id of the picture shown only after the correct answer.
    public internal(set) var pictureKey: String?

    /// Three help steps: two generic for the rung, then this item's worked example.
    public var helpKeys: [String] { ReadingENHelpLadder.keys(rung) + [workedHintKey] }
    public var workedHintKey: String { "reading.en.hint." + id }

    public internal(set) var stimulus = ReadingENStimulus(visibleGraphemes: [], tileChoices: [], speech: "")

    init(id: String, rung: ReadingENRung, activity: ReadingENActivity) {
        self.id = id
        self.rung = rung
        self.activity = activity
    }

    /// The stimulus follows the authored fields: graphemes or words are shown, tiles are offered as choices.
    private func withStimulus() -> ReadingENItem {
        var copy = self
        let shown = activity == .buildTiles ? [] : (graphemes.isEmpty ? words : graphemes)
        copy.stimulus = ReadingENStimulus(visibleGraphemes: shown, tileChoices: tiles,
                                          speech: phonemes.joined(separator: " "))
        return copy
    }

    func sounds(_ graphemes: [String], _ phonemes: [String]) -> ReadingENItem {
        var copy = self
        copy.graphemes = graphemes
        copy.phonemes = phonemes
        return copy.withStimulus()
    }

    func spelling(_ words: [String], tiles: [String] = []) -> ReadingENItem {
        var copy = self
        copy.words = words
        copy.tiles = tiles
        return copy.withStimulus()
    }

    func pictured(_ key: String?) -> ReadingENItem {
        var copy = self
        copy.pictureKey = key
        return copy
    }
}

/// The help ladder of each rung: two generic steps, the third shows a worked example for the item.
public enum ReadingENHelpLadder {
    public static func keys(_ rung: ReadingENRung) -> [String] {
        ["reading.en.help.\(rung.rawValue).1", "reading.en.help.\(rung.rawValue).2"]
    }

    /// The level-wide ladder: the two steps plus a closing step for the rung.
    public static func levelKeys(_ rung: ReadingENRung) -> [String] {
        keys(rung) + ["reading.en.help.\(rung.rawValue).3"]
    }
}

/// The picture of a reveal round stays hidden until the answer is right.
public struct ReadingENPresentation: Equatable, Sendable {
    public let pictureKey: String?
}

public struct ReadingENRevealModel: Sendable {
    /// Shared state, so a submit can be asked as a plain question without mutating the model.
    private final class State: @unchecked Sendable {
        var reveal: KitPictureReveal
        var solved = false
        init(answers: [String]) { reveal = KitPictureReveal(answers: answers) }
    }

    public let item: ReadingENItem
    private let state: State

    public init?(item: ReadingENItem) {
        guard item.pictureKey != nil, let word = item.words.first else { return nil }
        self.item = item
        self.state = State(answers: [word])
    }

    public var presentation: ReadingENPresentation {
        ReadingENPresentation(pictureKey: state.solved && state.reveal.pictureVisible ? item.pictureKey : nil)
    }

    public mutating func beginAnswering() { state.reveal.beginAnswering() }

    /// True for the right word; a wrong attempt leaves the picture hidden.
    @discardableResult
    public func submit(_ answer: String) -> Bool {
        guard answer.lowercased() == item.words.first else { return false }
        state.solved = true
        state.reveal.submit(answer)
        return true
    }
}
