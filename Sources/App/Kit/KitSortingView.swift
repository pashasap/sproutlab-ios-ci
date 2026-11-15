import SwiftUI
import Core

/// Sorting: bins carry Core icon keys; tokens are picked, then a bin is tapped.
struct KitSortingView: View {
    let sorting: KitSorting
    let language: Language
    let send: (KitCommand) -> Void

    var body: some View {
        let actions = sorting.accessibilityActions
        HStack(spacing: 12) {
            ForEach(sorting.tapTargets, id: \.identifier) { target in
                KitTargetButton(target: target, label: target.label(for: actions, language),
                                action: send) {
                    content(for: target)
                }
            }
        }
        .kitActions(actions, language: language) { send($0.command) }
        .kitAnnounce(sorting.announcements, language: language)
    }

    @ViewBuilder
    private func content(for target: KitTapTarget) -> some View {
        if case .tapBin(let index) = target.command, sorting.bins.indices.contains(index) {
            Image(systemName: sorting.bins[index].iconKey).foregroundStyle(Palette.accent)
        } else if target.command == .undo {
            Image(systemName: ChromeCatalog.symbolName(for: .back))
        } else {
            Text(target.subject ?? "").foregroundStyle(Palette.ink)
        }
    }
}
