import SwiftUI
import Core

/// Hands a kit reading item to the matching kit view. Taps and accessibility actions only go to
/// the view model's `send`; the view model judges them.
struct ReadingKitHost: View {
    let round: RoundViewModel
    let language: Language

    var body: some View {
        if let presentation = round.kitPresentation {
            component(presentation)
        }
    }

    @ViewBuilder
    private func component(_ presentation: ReadingKitPresentation) -> some View {
        switch presentation.component {
        case .slotBoard:
            if let board = round.kitSlotBoard {
                KitSlotBoardView(board: board, language: language, send: { round.send($0) })
            }
        case .tileSet:
            if let tiles = round.kitTileSet {
                KitTileSetView(tiles: tiles, language: language, send: { round.send($0) })
            }
        case .ordering:
            if let ordering = round.kitOrdering {
                KitOrderingView(ordering: ordering, language: language, send: { round.send($0) })
            }
        case .sorting:
            if let sorting = round.kitSorting {
                KitSortingView(sorting: sorting, language: language, send: { round.send($0) })
            }
        case .pictureReveal:
            revealView(presentation.pictureKey)
        }
    }

    @ViewBuilder
    private func revealView(_ pictureKey: String?) -> some View {
        if let reveal = round.kitReveal {
            KitPictureRevealView(reveal: reveal, language: language, send: { round.send($0) }) {
                if let key = pictureKey {
                    Image(key).resizable().scaledToFit().frame(maxHeight: 160)
                }
            }
        }
    }
}
