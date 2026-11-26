import SwiftUI
import Core

/// Draws the Math M4 model from Core presentation data: bundles of ten, loose units and the help labels.
struct M4View: View {
    let shown: M4Presentation
    let language: Language

    private let columns = QuestionStimulus.tenFrameColumns
    private let rows = QuestionStimulus.tenFrameSize / QuestionStimulus.tenFrameColumns

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                ForEach(0..<shown.bundleCount, id: \.self) { _ in bundle }
                if shown.looseCount > 0 {
                    looseUnits
                }
            }
            if shown.areTraysOpen {
                Text(verbatim: TextTable.string("m4.view.trays", language))
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
            }
            if let values = shown.bundleValues, !values.isEmpty {
                Text(verbatim: values.map(String.init).joined(separator: " + "))
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
            }
            if let contribution = shown.digitContribution {
                Text(verbatim: filled("m4.view.contribution", contribution))
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
            }
            HStack(spacing: 12) {
                ForEach(shown.buttons, id: \.kind) { button in
                    Text(verbatim: button.accessibilityLabel(language))
                        .font(.headline)
                        .foregroundStyle(Palette.ink)
                        .frame(minWidth: button.width, minHeight: button.height)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel(button.accessibilityLabel(language))
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SproutIdentifier.stimulus)
    }

    /// One bundle of ten: a full ten-frame block.
    private var bundle: some View {
        VStack(spacing: 3) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<columns, id: \.self) { column in
                        mark(isFilled: true, side: 8)
                            .accessibilityLabel(TextTable.string("m4.view.bundle", language))
                    }
                }
            }
        }
    }

    private var looseUnits: some View {
        HStack(spacing: 6) {
            ForEach(0..<shown.looseCount, id: \.self) { _ in
                mark(isFilled: true, side: 18)
            }
        }
    }

    private func mark(isFilled: Bool, side: Double) -> some View {
        RoundedRectangle(cornerRadius: side / 4)
            .fill(isFilled ? Palette.dot : Palette.card)
            .overlay(RoundedRectangle(cornerRadius: side / 4).stroke(Palette.ink, lineWidth: 1))
            .frame(width: side, height: side)
    }

    private func filled(_ key: String, _ value: Int) -> String {
        TextTable.string(key, language).replacingOccurrences(of: "%1", with: String(value))
    }
}
