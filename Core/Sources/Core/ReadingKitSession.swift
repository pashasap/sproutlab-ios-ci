/// Which interaction-kit component a reading item uses.
public enum ReadingKitComponentKind: Equatable, Sendable {
    case slotBoard, tileSet, ordering, sorting, pictureReveal
}

/// What the view shows of the kit: the component, and the picture only once the right word was submitted.
public struct ReadingKitPresentation: Equatable, Sendable {
    public let component: ReadingKitComponentKind
    public let pictureKey: String?
}

/// What Core decides after a kit command: nothing yet, a correct answer, or a wrong one.
enum KitVerdict: Equatable {
    case pending, correct, wrong
}

/// The kit state of the current reading item, with the rules that judge it.
struct ReadingKitSession {
    enum State {
        case board(KitSlotBoard)
        case tiles(KitTileSet)
        case ordering(KitOrdering)
        case sorting(KitSorting)
        case reveal(ReadingRevealModel)
    }

    let item: ReadingBankItem
    private(set) var state: State

    /// The session of a bank item; nil for a tap-only item.
    init?(item: ReadingBankItem) {
        guard let state = Self.initialState(item) else { return nil }
        self.item = item
        self.state = state
    }

    /// The session for the question shown; nil for math, notices and tap-only items.
    static func make(for question: Item) -> ReadingKitSession? {
        guard !question.isNotice, let id = question.readingId, let bank = ReadingBank.item(id: id) else { return nil }
        return ReadingKitSession(item: bank)
    }

    private static func initialState(_ item: ReadingBankItem) -> State? {
        switch (item.rung, item.r2Activity, item.r3Activity, item.activity) {
        case (.r2, .buildWord?, _, _): return .board(ReadingR2Build.board(for: item))
        case (.r2, .decodeReveal?, _, _): return ReadingRevealModel(item: item).map { .reveal($0) }
        case (.r3, _, .selectDigraph?, _): return .tiles(ReadingR3Select.tileSet(for: item))
        case (.r3, _, .blendWord?, _): return .board(ReadingR3Blend.board(for: item))
        case (.r3, _, .repairSplit?, _): return .tiles(ReadingR3Repair.tileSet(for: item))
        case (.r1, _, _, .sequenceSounds): return orderingState(item)
        case (.r1, _, _, .blendNew): return sortingState(item)
        default: return nil
        }
    }

    private static func orderingState(_ item: ReadingBankItem) -> State? {
        let shuffled = Array(item.tokens.dropFirst()) + item.tokens.prefix(1)
        return (try? KitOrdering(tokens: shuffled)).map { .ordering($0) }
    }

    private static func sortingState(_ item: ReadingBankItem) -> State? {
        (try? KitSorting(tokens: item.palette, binLabelKeys: item.sortingBinKeys)).map { .sorting($0) }
    }

    var presentation: ReadingKitPresentation {
        switch state {
        case .board: return ReadingKitPresentation(component: .slotBoard, pictureKey: nil)
        case .tiles: return ReadingKitPresentation(component: .tileSet, pictureKey: nil)
        case .ordering: return ReadingKitPresentation(component: .ordering, pictureKey: nil)
        case .sorting: return ReadingKitPresentation(component: .sorting, pictureKey: nil)
        case .reveal(let model):
            return ReadingKitPresentation(component: .pictureReveal, pictureKey: model.presentation.pictureKey)
        }
    }

    var tapTargets: [KitTapTarget] {
        switch state {
        case .board(let part): return part.tapTargets
        case .tiles(let part): return part.tapTargets
        case .ordering(let part): return part.tapTargets
        case .sorting(let part): return part.tapTargets
        case .reveal(let model): return model.reveal.tapTargets
        }
    }

    var accessibilityActions: [KitAccessibilityAction] {
        switch state {
        case .board(let part): return part.accessibilityActions
        case .tiles(let part): return part.accessibilityActions
        case .ordering(let part): return part.accessibilityActions
        case .sorting(let part): return part.accessibilityActions
        case .reveal(let model): return model.reveal.accessibilityActions
        }
    }

    var announcements: [KitAnnouncement] {
        switch state {
        case .board(let part): return part.announcements
        case .tiles(let part): return part.announcements
        case .ordering(let part): return part.announcements
        case .sorting(let part): return part.announcements
        case .reveal(let model): return model.reveal.announcements
        }
    }

    /// Applies one command (taps and accessibility actions both come here) and judges the new state.
    mutating func apply(_ command: KitCommand) -> KitVerdict {
        switch state {
        case .board(var part):
            let before = part
            part.apply(command)
            state = .board(part)
            return before != part ? boardVerdict(part, command) : .pending
        case .tiles(var part):
            let before = part
            part.apply(command)
            state = .tiles(part)
            return before != part ? tilesVerdict(part) : .pending
        case .ordering(var part):
            let before = part
            part.apply(command)
            state = .ordering(part)
            return before != part && part.order == item.tokens ? .correct : .pending
        case .sorting(var part):
            let before = part
            part.apply(command)
            state = .sorting(part)
            return before != part ? sortingVerdict(part) : .pending
        case .reveal(var model):
            let verdict = applyReveal(command, to: &model)
            state = .reveal(model)
            return verdict
        }
    }

    private func boardVerdict(_ board: KitSlotBoard, _ command: KitCommand) -> KitVerdict {
        guard case .place = command, board.complete else { return .pending }
        let right = item.rung == .r3
            ? ReadingR3Blend.isCorrect(board: board, item: item)
            : ReadingR2Build.isCorrect(board: board, item: item)
        return right ? .correct : .wrong
    }

    private func tilesVerdict(_ tiles: KitTileSet) -> KitVerdict {
        if item.r3Activity == .repairSplit {
            return ReadingR3Repair.isComplete(tileSet: tiles, item: item) ? .correct : .pending
        }
        guard tiles.pickedLetters.count == 2 else { return .pending }
        return ReadingR3Select.isCorrect(tileSet: tiles, item: item) ? .correct : .wrong
    }

    /// The first bin holds the sounds the word uses, the second the ones it does not.
    private func sortingVerdict(_ sorting: KitSorting) -> KitVerdict {
        guard sorting.complete else { return .pending }
        let used = Set(item.tokens)
        let right = sorting.bins[0].tokens.allSatisfy { used.contains($0) }
            && sorting.bins[1].tokens.allSatisfy { !used.contains($0) }
        return right ? .correct : .wrong
    }

    private func applyReveal(_ command: KitCommand, to model: inout ReadingRevealModel) -> KitVerdict {
        switch command {
        case .beginAnswering:
            model.beginAnswering()
        case .submit(let answer):
            return model.submit(answer) ? .correct : .wrong
        case .reset:
            model.reset()
        default:
            break
        }
        return .pending
    }
}

extension ReadingBankItem {
    /// Text keys naming the two sorting bins: the sounds the word uses, then the sounds it does not.
    var sortingBinKeys: [String] { ["kit.bin.uses.what", "kit.bin.avoids.what"] }
}

extension RoundViewModel {
    /// The kit component of the current item; nil for math and tap-only reading items.
    public var kitPresentation: ReadingKitPresentation? { kit?.presentation }
    public var kitTapTargets: [KitTapTarget] { kit?.tapTargets ?? [] }
    public var kitAccessibilityActions: [KitAccessibilityAction] { kit?.accessibilityActions ?? [] }
    public var kitAnnouncements: [KitAnnouncement] { kit?.announcements ?? [] }

    /// The current component value, for the view to draw; nil when the item uses another component.
    public var kitSlotBoard: KitSlotBoard? {
        if case .board(let part)? = kit?.state { return part }
        return nil
    }

    public var kitTileSet: KitTileSet? {
        if case .tiles(let part)? = kit?.state { return part }
        return nil
    }

    public var kitOrdering: KitOrdering? {
        if case .ordering(let part)? = kit?.state { return part }
        return nil
    }

    public var kitSorting: KitSorting? {
        if case .sorting(let part)? = kit?.state { return part }
        return nil
    }

    public var kitReveal: KitPictureReveal? {
        if case .reveal(let model)? = kit?.state { return model.reveal }
        return nil
    }

    /// The one path for kit taps and accessibility actions. A correct kit state answers the item with
    /// the correct index and source `.kit`; a wrong one takes the ordinary wrong-answer path.
    public func send(_ command: KitCommand) {
        guard var session = kit else { return }
        let verdict = session.apply(command)
        kit = session
        switch verdict {
        case .pending: return
        case .correct: answerFromKit(correct: true)
        case .wrong: answerFromKit(correct: false)
        }
    }

    /// Tap to Hear for the current item: speaks the full sentence line, only on this explicit command.
    public func hear(speech: any SpeechService) {
        _ = try? speech.speak(voiceTag: language == .fr ? "fr-FR" : "en-US", text: speechText)
    }
}
