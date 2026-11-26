import SwiftUI
import Core

/// One trail tile drawn from its Core presentation: state glyph, markers, identities, accessibility.
struct TrailTileView: View {
    let tile: TrailTileLayout
    let language: Language
    let onTap: () -> Void

    private var info: TrailTilePresentation { tile.presentation }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                glyphs
                Text(info.title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(info.isEnabled ? Palette.ink : Palette.locked)
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: tile.touchHeight, alignment: .leading)
            .frame(width: tile.touchWidth)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
            .overlay {
                if info.isHighlighted {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Palette.token(info.stateColourToken), lineWidth: 3)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!info.isEnabled)
        .accessibilityLabel(tile.spokenLabel)
        .accessibilityIdentifier(info.identifier)
    }

    private var glyphs: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) { stateGlyphs; identityGlyphs }
            VStack(alignment: .leading, spacing: 4) { stateGlyphs; identityGlyphs }
        }
        .dynamicTypeSize(...DynamicTypeSize.large)
    }

    private var stateGlyphs: some View {
        HStack(spacing: 6) {
            Image(systemName: info.stateSymbolName).font(.title2)
                .foregroundStyle(Palette.token(info.stateColourToken))
            markers
        }
    }

    private var identityGlyphs: some View {
        HStack(spacing: 6) {
            ForEach(info.identities, id: \.iconKind) { identity in
                IdentityBadge(identity: identity, language: language)
            }
        }
    }

    @ViewBuilder
    private var markers: some View {
        if let symbol = info.reviewSymbolName {
            Image(systemName: symbol).font(.title3)
                .foregroundStyle(Palette.token(info.stateColourToken))
        }
        if let symbol = info.highlightSymbolName {
            Image(systemName: symbol).font(.title3)
                .foregroundStyle(Palette.token(info.stateColourToken))
        }
    }
}
