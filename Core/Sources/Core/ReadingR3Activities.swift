/// Select the digraph: one tile holds the grapheme, the others are single letters of the word.
public enum ReadingR3Select {
    public static func tileSet(for item: ReadingBankItem) -> KitTileSet {
        KitTileSet(kind: .letter, tiles: item.palette, colourToken: .purple)
    }

    public static func isCorrect(tileSet: KitTileSet, item: ReadingBankItem) -> Bool {
        item.grapheme != nil && tileSet.selectedToken == item.grapheme
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

/// Repair a split grapheme: two letter tiles that the child joins back into one unit.
public enum ReadingR3Repair {
    public static func tileSet(for item: ReadingBankItem) -> KitTileSet {
        KitTileSet(splitGrapheme: item.tokens, colourToken: .purple)
    }

    public static func isComplete(tileSet: KitTileSet, item: ReadingBankItem) -> Bool {
        item.grapheme != nil && tileSet.tiles == [item.grapheme ?? ""]
    }
}
