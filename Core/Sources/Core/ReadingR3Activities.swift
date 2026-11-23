/// Select the digraph: every letter of the word is a tile; the child taps the two adjacent letters of the digraph.
public enum ReadingR3Select {
    public static func tileSet(for item: ReadingBankItem) -> KitTileSet {
        KitTileSet(letters: item.words.first ?? "", pair: item.grapheme ?? "", colourToken: .purple)
    }

    public static func isCorrect(tileSet: KitTileSet, item: ReadingBankItem) -> Bool {
        item.grapheme != nil && tileSet.pairPicked
    }
}

/// Blend a word from grouped units: ch and ou are one tile each; done when the slots spell the word.
public enum ReadingR3Blend {
    public static func board(for item: ReadingBankItem) -> KitSlotBoard {
        KitSlotBoard(slotCount: item.tokens.count, palette: item.palette)
    }

    public static func isCorrect(board: KitSlotBoard, item: ReadingBankItem) -> Bool {
        board.complete && board.slots.compactMap { $0 }.joined() == item.words.first
    }
}

/// Repair a split grapheme: the word is cut into chunks (the grapheme split across two of them)
/// that the child moves back into order.
public enum ReadingR3Repair {
    /// The word cut around its grapheme, e.g. rouler into ro, u, ler.
    public static func chunks(for item: ReadingBankItem) -> [String] {
        let word = item.words.first ?? ""
        guard let grapheme = item.grapheme, grapheme.count == 2, let range = word.range(of: grapheme) else {
            return [word]
        }
        let prefix = String(word[..<range.lowerBound]), suffix = String(word[range.upperBound...])
        let first = String(grapheme.first ?? " "), second = String(grapheme.last ?? " ")
        return [prefix + first, second, suffix].filter { !$0.isEmpty }
    }

    public static func tileSet(for item: ReadingBankItem) -> KitTileSet {
        let pieces = chunks(for: item)
        let shifted = pieces.count > 1 ? Array(pieces.dropFirst()) + pieces.prefix(1) : pieces
        return KitTileSet(chunks: shifted, colourToken: .purple)
    }

    public static func isComplete(tileSet: KitTileSet, item: ReadingBankItem) -> Bool {
        tileSet.tiles.joined() == item.words.first
    }
}
