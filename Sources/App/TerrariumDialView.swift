import SwiftUI
import Core

/// The sun and moon dial: a disc with two phases, day and night; a tap toggles between them.
struct TerrariumDialView: View {
    let frame: TerrariumFrame
    let scheme: ColourScheme
    let language: Language
    let value: String
    let animates: Bool
    let onToggle: () -> Void

    var body: some View {
        let state = frame.dial
        let sky = frame.sky(scheme)
        let night = state.phase == .night
        Button(action: onToggle) {
            Canvas { context, size in
                let side = min(size.width, size.height)
                let disc = CGRect(x: (size.width - side) / 2, y: (size.height - side) / 2, width: side, height: side)
                context.fill(Path(ellipseIn: disc), with: .color(TerrariumSkyView.colour(sky.top)))
                let mark = CGRect(x: disc.midX - side / 8, y: disc.minY + side / 8, width: side / 4, height: side / 4)
                context.fill(Path(ellipseIn: mark), with: .color(TerrariumSkyView.colour(sky.bottom)))
            }
            .accessibilityIgnoresInvertColors()
            .rotationEffect(.degrees(night ? 180 : 0))
            .animation(animates ? .easeInOut(duration: 0.4) : nil, value: night)
        }
        .buttonStyle(.plain)
        .frame(width: state.hitSize.width, height: state.hitSize.height)
        .contentShape(Rectangle())
        .accessibilityLabel(SunMoonDial.accessibilityLabel(language))
        .accessibilityValue(value)
    }
}
