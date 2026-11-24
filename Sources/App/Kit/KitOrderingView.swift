import SwiftUI
import Core

/// Ordering row: drag a tile to a new place or tap it to move it along; Undo is always visible.
/// VoiceOver gets earlier/later for every token. Tiles show their sound and are named "Position N".
/// At accessibility sizes the tiles stack so nothing is cut off.
struct KitOrderingView: View {
    let ordering: KitOrdering
    let language: Language
    let send: (KitCommand) -> Void
    var tiles: [ReadingTilePresentation] = []

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var stacked: Bool { typeSize.isAccessibilitySize }
    private var pitch: Double { KitMetrics.minTarget + 12 }

    var body: some View {
        let actions = ordering.accessibilityActions
        let layout = stacked ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
        layout {
            ForEach(Array(ordering.tapTargets.enumerated()), id: \.element.identifier) { index, target in
                tile(target, index, actions)
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.3), value: ordering.order)
        .kitActions(actions, language: language) { send($0.command) }
        .kitAnnounce(ordering.announcements, language: language)
    }

    @ViewBuilder
    private func tile(_ target: KitTapTarget, _ index: Int, _ actions: [KitAccessibilityAction]) -> some View {
        if target.command == .undo {
            KitTargetButton(target: target, label: TextTable.string("kit.action.undo", language), action: send) {
                Image(systemName: ChromeCatalog.symbolName(for: .back))
            }
        } else {
            KitTargetButton(target: target, label: label(target, index, actions), action: send) {
                Text(target.subject ?? "").font(.title2).foregroundStyle(Palette.ink)
                    .lineLimit(nil).fixedSize(horizontal: false, vertical: true)
            }
            .simultaneousGesture(drag(target, index))
        }
    }

    private func drag(_ target: KitTapTarget, _ index: Int) -> some Gesture {
        DragGesture(minimumDistance: 12).onEnded { value in
            guard let token = target.subject else { return }
            let distance = stacked ? value.translation.height : value.translation.width
            let steps = Int((distance / pitch).rounded())
            for _ in 0..<abs(steps) { send(steps > 0 ? .moveLater(token) : .moveEarlier(token)) }
        }
    }

    private func label(_ target: KitTapTarget, _ index: Int, _ actions: [KitAccessibilityAction]) -> String {
        let base = target.label(for: actions, language)
        guard tiles.indices.contains(index) else { return base }
        return tiles[index].positionLabel + ", " + base
    }
}
