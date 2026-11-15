import SwiftUI
import Core

/// Answer buttons; the picture slot stays empty until Core says the picture is visible.
struct KitPictureRevealView<Picture: View>: View {
    let reveal: KitPictureReveal
    let language: Language
    let send: (KitCommand) -> Void
    @ViewBuilder let picture: () -> Picture

    var body: some View {
        let actions = reveal.accessibilityActions
        VStack(spacing: 12) {
            if reveal.pictureVisible { picture() }
            HStack(spacing: 12) {
                ForEach(reveal.tapTargets, id: \.identifier) { target in
                    KitTargetButton(target: target, label: target.label(for: actions, language),
                                    action: send) {
                        Text(target.subject ?? "").foregroundStyle(Palette.ink)
                    }
                }
            }
        }
        .kitActions(actions, language: language) { send($0.command) }
        .kitAnnounce(reveal.announcements, language: language)
    }
}
