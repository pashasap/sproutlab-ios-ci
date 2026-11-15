import SwiftUI
import Core

/// The make-10 icon drawn in code from the Core spec: rows of slots, filled ones solid, the gap outlined.
struct TenFrameIconView: View {
    let spec: TenFrameIconSpec
    private let slot: CGFloat = 8
    private let gap: CGFloat = 2

    var body: some View {
        VStack(spacing: gap) {
            ForEach(0..<spec.rows, id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach(0..<spec.columns, id: \.self) { column in
                        slotView(index: row * spec.columns + column)
                    }
                }
            }
        }
        .padding(3)
        .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(lineWidth: 1.5) }
    }

    @ViewBuilder
    private func slotView(index: Int) -> some View {
        if spec.emptySlotIndices.contains(index) {
            RoundedRectangle(cornerRadius: 2).strokeBorder(lineWidth: 1.5).frame(width: slot, height: slot)
        } else {
            RoundedRectangle(cornerRadius: 2).frame(width: slot, height: slot)
        }
    }
}
