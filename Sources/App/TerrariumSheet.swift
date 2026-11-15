import SwiftUI
import Core

/// The star button's sheet: renders the Core content; the ring text is only its accessibility label.
struct TerrariumSheet: View {
    let content: TerrariumSheetContent
    let accessibilityLabel: String
    let onClose: () -> Void

    var body: some View {
        Group {
            switch content {
            case let .terrarium(model): TerrariumView(model: model, onBack: onClose)
            case let .ringText(text): Text(text).font(.title2.weight(.semibold)).padding(32)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(SproutIdentifier.terrariumView)
    }
}
