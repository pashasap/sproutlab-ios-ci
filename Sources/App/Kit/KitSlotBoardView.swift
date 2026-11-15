import SwiftUI
import Core

/// Slot board: slots on top, palette below, an always-visible undo control. Taps go to `send`.
struct KitSlotBoardView: View {
    let board: KitSlotBoard
    let language: Language
    let send: (KitCommand) -> Void

    var body: some View {
        let actions = board.accessibilityActions
        HStack(spacing: 12) {
            ForEach(board.tapTargets, id: \.identifier) { target in
                KitTargetButton(target: target, label: target.label(for: actions, language),
                                action: send) {
                    content(for: target)
                }
            }
        }
        .kitActions(actions, language: language) { send($0.command) }
        .kitAnnounce(board.announcements, language: language)
    }

    @ViewBuilder
    private func content(for target: KitTapTarget) -> some View {
        if target.command == .undo {
            Image(systemName: ChromeCatalog.symbolName(for: .back))
        } else if let token = target.subject {
            Text(token).foregroundStyle(Palette.ink)
        } else {
            Color.clear
        }
    }
}
