import SwiftUI
import Core

/// Ordering row: tap a token to move it along; VoiceOver gets earlier/later for every token.
struct KitOrderingView: View {
    let ordering: KitOrdering
    let language: Language
    let send: (KitCommand) -> Void

    var body: some View {
        let actions = ordering.accessibilityActions
        HStack(spacing: 12) {
            ForEach(ordering.tapTargets, id: \.identifier) { target in
                KitTargetButton(target: target, label: target.label(for: actions, language),
                                action: send) {
                    Text(target.subject ?? "").foregroundStyle(Palette.ink)
                }
            }
        }
        .kitActions(actions, language: language) { send($0.command) }
        .kitAnnounce(ordering.announcements, language: language)
    }
}
