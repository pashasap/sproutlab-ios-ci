import SwiftUI
import Core

/// Draws the Math M3 stimulus from Core presentation data: the two ten-frames and the help amounts.
struct M3View: View {
    let shown: M3Presentation
    let label: String
    let language: Language

    private let columns = QuestionStimulus.tenFrameColumns
    private let rows = QuestionStimulus.tenFrameSize / QuestionStimulus.tenFrameColumns

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 18) {
                ForEach(Array(shown.frames.enumerated()), id: \.offset) { _, frame in
                    grid(frame)
                }
            }
            if shown.removeAmount > 0 {
                Text(verbatim: filled("m3.view.remove", shown.removeAmount))
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
            }
            if let separated = shown.separatedToTen {
                Text(verbatim: filled("m3.view.separate", separated))
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
            }
            if let rest = shown.remainderAfterFirstStep {
                Text(verbatim: filled("m3.view.rest", rest))
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
        .accessibilityIdentifier(SproutIdentifier.stimulus)
    }

    private func grid(_ frame: M3TenFrame) -> some View {
        VStack(spacing: 6) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<columns, id: \.self) { column in
                        cell(frame, row * columns + column)
                    }
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(Palette.ink, lineWidth: shown.areFramesRevealed ? 3 : 1))
    }

    private func cell(_ frame: M3TenFrame, _ index: Int) -> some View {
        let isFilled = frame.filled.contains(index)
        return RoundedRectangle(cornerRadius: 6)
            .fill(isFilled ? Palette.dot : Palette.card)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.ink, lineWidth: isFilled ? 2 : 1))
            .frame(width: 30, height: 30)
    }

    private func filled(_ key: String, _ value: Int) -> String {
        TextTable.string(key, language).replacingOccurrences(of: "%1", with: String(value))
    }

    private var value: String {
        shown.filledCounts.map { String($0) }.joined(separator: " + ")
    }
}
