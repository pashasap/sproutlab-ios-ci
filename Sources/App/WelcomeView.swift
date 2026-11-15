import SwiftUI
import Core

struct WelcomeView: View {
    let app: AppViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: ChromeCatalog.brandSymbolName)
                .font(.system(size: 96))
                .foregroundStyle(Palette.accent)
                .accessibilityHidden(true)
            Text(TextTable.string("welcome.tagline", app.language))
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.ink)
            Button { app.play() } label: {
                Label(TextTable.string("welcome.play", app.language), systemImage: ChromeCatalog.symbolName(for: .play))
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel(TextTable.string("a11y.play", app.language))
            noticeView
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var noticeView: some View {
        if let key = app.notice {
            Text(TextTable.string(key, app.language))
                .font(.callout)
                .foregroundStyle(Palette.locked)
                .multilineTextAlignment(.center)
        }
    }
}
