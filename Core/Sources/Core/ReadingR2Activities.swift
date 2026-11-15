/// What the view may show of a decode item: the word, and the picture only after the correct answer.
public struct ReadingRevealPresentation: Equatable, Sendable {
    public let word: String
    public let pictureKey: String?
}

/// Read-then-reveal: the picture of a decode item stays hidden until the correct word is submitted.
public struct ReadingRevealModel: Sendable {
    private let item: ReadingBankItem
    public private(set) var reveal: KitPictureReveal

    public init?(item: ReadingBankItem) {
        guard item.r2Activity == .decodeReveal, item.pictureKey != nil, !item.words.isEmpty else { return nil }
        self.item = item
        reveal = KitPictureReveal(answers: item.palette)
    }

    public var presentation: ReadingRevealPresentation {
        ReadingRevealPresentation(word: item.words[0], pictureKey: reveal.pictureVisible ? item.pictureKey : nil)
    }

    public mutating func beginAnswering() {
        reveal.beginAnswering()
    }

    public mutating func reset() {
        reveal.reset()
    }

    /// True only for the item's own word; a wrong answer leaves the picture hidden.
    public mutating func submit(_ answer: String) -> Bool {
        guard answer == item.words[0] else { return false }
        reveal.submit(answer)
        return true
    }
}

/// Change one grapheme: only a word of the R1 or R2 bank that differs by exactly one letter counts.
public enum ReadingR2Change {
    static let vocabulary: Set<String> = Set(
        (ReadingBank.items(rung: .r1) + ReadingBank.items(rung: .r2))
            .filter { $0.status == .approved }.flatMap(\.words).map { $0.lowercased() })

    public static func accepts(start: String, candidate: String) -> Bool {
        let first = Array(start.lowercased()), second = Array(candidate.lowercased())
        guard !second.isEmpty, first.count == second.count, vocabulary.contains(candidate.lowercased()) else {
            return false
        }
        return zip(first, second).filter { $0 != $1 }.count == 1
    }
}

/// Build a word from letter tiles: done only when every slot is filled and the slots spell the target.
public enum ReadingR2Build {
    public static func board(for item: ReadingBankItem) -> KitSlotBoard {
        KitSlotBoard(slotCount: item.tokens.count, palette: item.palette)
    }

    public static func tileSet(for item: ReadingBankItem) -> KitTileSet {
        KitTileSet(kind: .letter, tiles: item.palette, colourToken: .purple)
    }

    public static func isCorrect(board: KitSlotBoard, item: ReadingBankItem) -> Bool {
        board.complete && board.slots.compactMap { $0 }.joined() == item.words.first
    }
}
