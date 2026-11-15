import SwiftUI
import Core

/// One trail tile drawn from its Core presentation: state glyph, markers, identities, accessibility.
struct TrailTileView: View {
    let tile: TrailTile
    let language: Language
    let onTap: () -> Void

    private var info: TrailTilePresentation { tile.presentation }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: info.stateSymbolName)
                    .font(.title2)
                    .foregroundStyle(Palette.token(info.stateColourToken))
                Text(info.title).font(.title3.weight(.semibold)).multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                markers
                ForEach(info.identities, id: \.iconKind) { identity in
                    IdentityBadge(identity: identity, language: language)
                }
            }
            .foregroundStyle(info.isEnabled ? Palette.ink : Palette.locked)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: Touch.minimumPoints)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                if info.isHighlighted {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Palette.token(info.stateColourToken), lineWidth: 3)
                }
            }
        }
        .disabled(!info.isEnabled)
        .accessibilityLabel(info.accessibilityLabel)
        .accessibilityIdentifier(info.identifier)
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
