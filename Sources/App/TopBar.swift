import SwiftUI
import Core

/// Persistent bar: icon/title (hold 3 s for diagnostics), language, music and star total.
struct TopBar: View {
    let app: AppViewModel
    let onTitleHold: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    private var mode: TopBarMode { TopBarLayout.mode(for: typeSize.coreCategory) }
    private var isCompact: Bool { typeSize.isAccessibilitySize }

    var body: some View {
        // Label (a11y.title) and identifier come from the shared interaction; SproutIdentifier.icon stays defined in Core.
        let iconButton = AppIconImage()
            .frame(minWidth: Touch.minimumPoints, minHeight: Touch.minimumPoints)
            .titleInteraction(shared, app: app, onHold: onTitleHold)
        // First option: icon + title + controls. Fallback: the tappable icon replaces the title text.
        ViewThatFits(in: .horizontal) {
            bar { iconButton; title.fixedSize(horizontal: true, vertical: false) }
            bar { iconButton }
        }
        .background(Palette.card)
        // The title is never truncated and "FR" never wraps; Larger Text is capped on the bar itself.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    private func bar<Leading: View>(@ViewBuilder leading: () -> Leading) -> some View {
        HStack(spacing: isCompact ? 2 : 8) {
            leading()
            Spacer(minLength: 0)
            languageButton
            musicButton
            stars
        }
        .padding(.horizontal, isCompact ? 4 : 16)
        .padding(.vertical, 8)
    }

    private var shared: TitleInteraction {
        TopBarLayout.titleInteraction(mode: mode, language: app.language)
    }

    private var title: some View {
        Text(ChromeCatalog.title(language: app.language).text)
            .font(.title2.weight(.bold))
            .foregroundStyle(Palette.ink)
            .frame(minHeight: Touch.minimumPoints)
            .titleInteraction(shared, app: app, onHold: onTitleHold)
            .accessibilityAddTraits(.isHeader)
    }

    /// Two segments, FR and GB, both always visible; the current one is outlined, bold, underlined and selected.
    private var languageButton: some View {
        HStack(spacing: 2) {
            ForEach(Language.allCases, id: \.self) { language in
                languageSegment(language)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(TextTable.string("a11y.language", app.language))
        .accessibilityIdentifier(SproutIdentifier.language)
    }

    @ViewBuilder
    private func languageSegment(_ language: Language) -> some View {
        let code = language.rawValue.uppercased()
        if let segment = LanguageControl.segments(current: app.language).first(where: { $0.code == code }) {
            Button { app.setLanguage(language) } label: {
                segmentLabel(segment)
            }
            .accessibilityLabel(segment.accessibilityLabel)
            .accessibilityAddTraits(segment.isSelected ? .isSelected : [])
        }
    }

    private func segmentLabel(_ segment: LanguageSegment) -> some View {
        VStack(spacing: 0) {
            Text(segment.flag == .fr ? "🇫🇷" : "🇬🇧").accessibilityHidden(true)
            Text(segment.code)
                .font(.headline)
                .fontWeight(segment.isSelected ? .heavy : .regular)
                .underline(segment.marker == .underline)
                .lineLimit(mode.languageLineLimit)
                .fixedSize()
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 4)
        .frame(minWidth: Touch.minimumPoints, minHeight: Touch.minimumPoints)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Palette.ink, lineWidth: segment.isSelected ? 2 : 0)
        }
    }

    private var musicButton: some View {
        Button { app.setMusic(!app.musicOn) } label: {
            GlyphView(glyph: ChromeCatalog.music(on: app.musicOn))
                .font(.title3)
                .foregroundStyle(Palette.ink)
                .frame(minWidth: Touch.minimumPoints, minHeight: Touch.minimumPoints)
        }
        .accessibilityLabel(music.accessibilityLabel)
        .accessibilityAddTraits(app.musicOn ? .isSelected : [])
        .accessibilityIdentifier(SproutIdentifier.music)
    }

    private var music: ChromeIcon {
        ChromeCatalog.musicIcon(on: app.musicOn, language: app.language)
    }

    private var stars: some View {
        let button = app.starButton
        return Button { app.openTerrarium() } label: {
            StarButtonLabel(button: button)
        }
        .accessibilityLabel(button.label)
        .accessibilityIdentifier(button.identifier)
    }
}

extension View {
    /// The one title interaction for the full title and the icon-only bar: tap goes home,
    /// a 3 s hold opens diagnostics (and never navigates); label and identifier come from Core.
    /// holdSeconds is TitleHold.threshold, set once in ChromeCatalog.titleInteraction.
    func titleInteraction(_ interaction: TitleInteraction, app: AppViewModel,
                          onHold: @escaping () -> Void) -> some View {
        self
            .contentShape(Rectangle())
            .onTapGesture { app.goHome() }
            .onLongPressGesture(minimumDuration: interaction.holdSeconds, perform: onHold)
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(interaction.accessibilityLabel)
            .accessibilityIdentifier(interaction.identifier)
    }
}
