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

/// Under an audit launch: no animations. Otherwise unchanged. The root identifier is not set here.
private struct AuditRoot: ViewModifier {
    let launch: AuditLaunch?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let launch {
            content.transaction { $0.disablesAnimations = !launch.animationsEnabled }
        } else {
            content
        }
    }
}

extension View {
    /// Attaches the audit stop's root identifier to this rendered view; nothing when `id` is nil.
    @ViewBuilder
    func auditRoot(_ id: String?) -> some View {
        if let id { accessibilityIdentifier(id) } else { self }
    }
}

struct RootView: View {
    let environment: AppEnvironment
    @State private var contentHeight: CGFloat = 0
    @State private var auditGallery = false
    @State private var auditJournal = false

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
                .auditRoot(root(for: .diagnostics))
        }
        .sheet(isPresented: Binding(get: { app.terrariumVisible },
                                    set: { app.setTerrariumVisible($0) })) {
            TerrariumSheet(content: environment.terrariumContent(),
                           accessibilityLabel: app.starButton.ringText,
                           onClose: { app.setTerrariumVisible(false) })
                .auditRoot(root(for: .terrarium))
        }
        .sheet(isPresented: $auditGallery) {
            GalleryView(language: app.language).auditRoot(root(for: .gallery))
        }
        .sheet(isPresented: $auditJournal) {
            if case let .terrarium(model) = environment.terrariumContent() {
                JournalView(model: model) { auditJournal = false }.auditRoot(root(for: .journal))
            }
        }
        .onAppear {
            auditGallery = environment.auditState?.screen == .gallery
            auditJournal = environment.auditState?.screen == .journal
        }
    }

    /// The audit root identifier when the audit stop opens `screen`; nil otherwise.
    private func root(for screen: AuditScreen) -> String? {
        guard let state = environment.auditState, state.screen == screen else { return nil }
        return state.rootId
    }

    private func measured(_ app: AppViewModel) -> some View {
        content(app)
            .background(GeometryReader { Color.clear.preference(key: ContentHeightKey.self, value: $0.size.height) })
            .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
    }

    @ViewBuilder
    private func content(_ app: AppViewModel) -> some View {
        switch app.screen {
        case .welcome: WelcomeView(app: app).auditRoot(root(for: .welcome))
        case .trail: TrailView(app: app).auditRoot(root(for: .trail))
        case .round: RoundScreen(app: app).auditRoot(root(for: .round))
        case .summary: SummaryView(app: app).auditRoot(root(for: .summary))
        }
    }
}
