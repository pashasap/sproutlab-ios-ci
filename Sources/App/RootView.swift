import SwiftUI
import Core

/// Shared control look: at least `Touch.minimumPoints` on both sides.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(Palette.onAccent)
            .padding(.horizontal, 24)
            .frame(minWidth: Touch.minimumPoints, minHeight: Touch.minimumPoints)
            .background(Palette.accent, in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

private struct ContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Under an audit launch: the root identifier from the Core value and no animations. Otherwise unchanged.
private struct AuditRoot: ViewModifier {
    let launch: AuditLaunch?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let launch {
            content
                .accessibilityIdentifier(launch.root)
                .transaction { $0.disablesAnimations = !launch.animationsEnabled }
        } else {
            content
        }
    }
}

struct RootView: View {
    let environment: AppEnvironment
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        let app = environment.app
        GeometryReader { proxy in
            let layout = LayoutPolicy.screenLayout(availableHeight: Double(proxy.size.height),
                                                   contentHeight: Double(contentHeight))
            VStack(spacing: 0) {
                TopBar(app: app, onTitleHold: { app.titleLongPressCompleted() })
                    .zIndex(layout.topBarPinned ? 1 : 0)
                if layout.contentScrolls {
                    ScrollView { measured(app) }
                } else {
                    measured(app)
                }
            }
        }
        .background(Palette.background.ignoresSafeArea())
        .modifier(AuditRoot(launch: environment.audit))
        .sheet(isPresented: Binding(get: { app.diagnosticsVisible },
                                    set: { app.setDiagnosticsVisible($0) })) {
            DiagnosticsSheet(model: environment.diagnostics, language: app.language)
        }
        .sheet(isPresented: Binding(get: { app.terrariumVisible },
                                    set: { app.setTerrariumVisible($0) })) {
            TerrariumSheet(content: environment.terrariumContent(),
                           accessibilityLabel: app.starButton.ringText,
                           onClose: { app.setTerrariumVisible(false) })
        }
    }

    private func measured(_ app: AppViewModel) -> some View {
        content(app)
            .background(GeometryReader { Color.clear.preference(key: ContentHeightKey.self, value: $0.size.height) })
            .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
    }

    @ViewBuilder
    private func content(_ app: AppViewModel) -> some View {
        switch app.screen {
        case .welcome: WelcomeView(app: app)
        case .trail: TrailView(app: app)
        case .round: RoundScreen(app: app)
        case .summary: SummaryView(app: app)
        }
    }
}
