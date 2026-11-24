import SwiftUI
import Core

/// The question prompt built from Core segments: keywords in the activity colour, led by the identity icon.
struct PromptView: View {
    let identity: ActivityIdentity
    let language: Language
    /// English prompt of an English reading item; when set it replaces the table prompt.
    var englishText: String = ""
    /// Written formula such as "3 + 7 = ?" for an addition or subtraction round.
    var formula: String?

    var body: some View {
        VStack(spacing: 8) {
            IdentityBadge(identity: identity, language: language)
            (englishText.isEmpty ? segments : Text(verbatim: englishText)).font(.title.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.ink)
            if let formula {
                Text(verbatim: formula).font(.largeTitle.weight(.bold)).foregroundStyle(Palette.ink)
            }
        }
    }

    private var segments: Text {
        identity.promptSegments(language).reduce(Text(verbatim: String())) { result, segment in
            if let token = segment.colourToken {
                return result + Text(segment.text).foregroundStyle(Palette.activity(token)).underline()
            }
            return result + Text(segment.text)
        }
    }
}

/// The activity identity icon in its colour; decorative next to text, named for VoiceOver.
struct IdentityBadge: View {
    let identity: ActivityIdentity
    let language: Language

    var body: some View {
        icon
            .foregroundStyle(Palette.activity(identity.colourToken))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(identity.accessibilityName(language))
    }

    /// Make-10 is drawn in code from the Core ten-frame spec; the symbol is the fallback for other kinds.
    @ViewBuilder
    private var icon: some View {
        if identity.iconKind == .tenFrameGap {
            TenFrameIconView(spec: ChromeCatalog.tenFrameIcon)
        } else {
            Image(systemName: ChromeCatalog.activitySymbolName(identity.iconKind)).font(.title)
        }
    }
}
