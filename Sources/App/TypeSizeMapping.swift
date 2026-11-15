import SwiftUI
import Core

extension DynamicTypeSize {
    /// The Core size category, so Core alone decides the top bar mode.
    var coreCategory: TypeSizeCategory {
        switch self {
        case .xSmall: return .xSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .xLarge
        case .xxLarge: return .xxLarge
        case .xxxLarge: return .xxxLarge
        case .accessibility1: return .accessibility1
        case .accessibility2: return .accessibility2
        case .accessibility3: return .accessibility3
        case .accessibility4: return .accessibility4
        case .accessibility5: return .accessibility5
        @unknown default: return .accessibility5
        }
    }
}

/// A glyph from Core: the symbol, with a drawn diagonal slash when Core says so.
struct GlyphView: View {
    let glyph: ChromeGlyph

    var body: some View {
        Image(systemName: glyph.symbolName)
            .scaleEffect(glyph.scale)
            .overlay {
                if glyph.slash { slash }
            }
    }

    /// Slash from the Core spec: top-left to bottom-right, longer than the note, with a background knockout outline.
    private var slash: some View {
        let spec = ChromeCatalog.musicSlash
        return GeometryReader { proxy in
            let length = max(proxy.size.width, proxy.size.height) * glyph.scale * (1 + 2 * spec.overhang)
            ZStack {
                Capsule().fill(Palette.card)
                    .frame(width: spec.strokeWidth + 2 * spec.knockoutWidth, height: length + 2 * spec.knockoutWidth)
                Capsule().fill(Palette.ink)
                    .frame(width: spec.strokeWidth, height: length)
            }
            .rotationEffect(.degrees(-spec.angleDegrees))
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .accessibilityHidden(true)
    }
}
