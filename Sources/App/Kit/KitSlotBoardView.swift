import SwiftUI
import Core

/// Slot board: slots on top, palette below, an always-visible undo control. Taps go to `send`.
/// Rows wrap at `LayoutPolicy.maximumSlotBoardTiles`; an empty slot is still named ("Case N vide").
struct KitSlotBoardView: View {
    let board: KitSlotBoard
    let language: Language
    let send: (KitCommand) -> Void
    var slotLabels: [String] = []

    private var slotPrefix: String { KitIdentifier.make("slot") + "." }
    private var slotTargets: [KitTapTarget] { board.tapTargets.filter { $0.identifier.hasPrefix(slotPrefix) } }
    private var otherTargets: [KitTapTarget] { board.tapTargets.filter { !$0.identifier.hasPrefix(slotPrefix) } }

    var body: some View {
        let actions = board.accessibilityActions
        let layout = LayoutPolicy.slotBoard(slotCount: slotTargets.count, tileCount: otherTargets.count,
                                            availableWidth: Double(UIScreen.main.bounds.width) - 48)
        VStack(spacing: 12) {
            rows(layout.slotRows, slotTargets, actions, isSlot: true)
            rows(layout.tileRows, otherTargets, actions, isSlot: false)
        }
        .kitActions(actions, language: language) { send($0.command) }
        .kitAnnounce(board.announcements, language: language)
    }

    private func rows(_ rows: [[Int]], _ targets: [KitTapTarget], _ actions: [KitAccessibilityAction],
                      isSlot: Bool) -> some View {
        ForEach(rows.indices, id: \.self) { row in
            HStack(spacing: 12) {
                ForEach(rows[row].filter { targets.indices.contains($0) }, id: \.self) { index in
                    let target = targets[index]
                    KitTargetButton(target: target, label: label(target, index, actions, isSlot), action: send) {
                        content(for: target)
                    }
                }
            }
        }
    }

    private func label(_ target: KitTapTarget, _ index: Int, _ actions: [KitAccessibilityAction],
                       _ isSlot: Bool) -> String {
        let spoken = target.label(for: actions, language)
        guard isSlot, spoken.isEmpty || target.subject == nil else { return spoken }
        return slotLabels.indices.contains(index) ? slotLabels[index] : spoken
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
