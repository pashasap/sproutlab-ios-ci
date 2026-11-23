import SwiftUI
import Core

struct WelcomeView: View {
    let app: AppViewModel

    private var presentation: WelcomePresentation { WelcomePresentation(language: app.language) }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: ChromeCatalog.brandSymbolName)
                .font(.system(size: 96))
                .foregroundStyle(Palette.accent)
                .accessibilityHidden(true)
            Text(presentation.titleText)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.ink)
            Text(presentation.tagline)
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.ink)
            ForEach(presentation.playControls, id: \.visibleLabel) { control in
                Button { app.play() } label: {
                    Label(control.visibleLabel, systemImage: ChromeCatalog.symbolName(for: .play))
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(minWidth: control.minimumWidth, minHeight: control.minimumHeight)
                .accessibilityLabel(control.spokenLabel)
            }
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
