import SwiftUI
import Core

/// The star icon inside the progress ring, with the next arrival's silhouette; no badge, no count.
struct StarButtonLabel: View {
    let button: StarButton

    var body: some View {
        ZStack {
            Circle().stroke(Palette.ink.opacity(0.2), lineWidth: 3)
            Circle()
                .trim(from: 0, to: button.ringFraction)
                .stroke(Palette.star, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: ChromeCatalog.symbolName(for: button.kind))
                .foregroundStyle(Palette.star)
            silhouette.offset(x: 16, y: 16)
        }
        .padding(4)
        .frame(width: button.minSide, height: button.minSide)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var silhouette: some View {
        switch button.silhouette {
        case .seed: Circle().fill(Palette.ink.opacity(0.5)).frame(width: 8, height: 8)
        case .egg: Ellipse().fill(Palette.ink.opacity(0.5)).frame(width: 8, height: 11)
        case .chrysalis: Capsule().fill(Palette.ink.opacity(0.5)).frame(width: 7, height: 13)
        }
    }
}
