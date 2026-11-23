import SwiftUI
import Core

/// Ordering row: tap a token to move it along; VoiceOver gets earlier/later for every token.
/// Tiles show their sound and are named "Position N" from the Core reading presentation.
struct KitOrderingView: View {
    let ordering: KitOrdering
    let language: Language
    let send: (KitCommand) -> Void
    var tiles: [ReadingTilePresentation] = []

    var body: some View {
        let actions = ordering.accessibilityActions
        HStack(spacing: 12) {
            ForEach(Array(ordering.tapTargets.enumerated()), id: \.element.identifier) { index, target in
                KitTargetButton(target: target, label: label(target, index, actions), action: send) {
                    Text(target.subject ?? "").foregroundStyle(Palette.ink)
                }
            }
        }
        .kitActions(actions, language: language) { send($0.command) }
        .kitAnnounce(ordering.announcements, language: language)
    }

    private func label(_ target: KitTapTarget, _ index: Int, _ actions: [KitAccessibilityAction]) -> String {
        let base = target.label(for: actions, language)
        guard tiles.indices.contains(index) else { return base }
        return tiles[index].positionLabel + ", " + base
    }
}
