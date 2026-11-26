import SwiftUI
import Core

/// Draws the Math M2 stimulus from Core presentation data: the ten-frame, the baskets and the equation.
struct M2View: View {
    let shown: M2Presentation
    let label: String

    private let columns = QuestionStimulus.tenFrameColumns
    private let rows = QuestionStimulus.tenFrameSize / QuestionStimulus.tenFrameColumns

    var body: some View {
        VStack(spacing: 14) {
            if !shown.frame.filled.isEmpty || !shown.frame.empty.isEmpty { frame }
            if !shown.baskets.isEmpty { baskets }
            if showsEquation { equation }
            if let moved = shown.movedPartIndex { worked(moved) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(summary)
        .accessibilityIdentifier(SproutIdentifier.stimulus)
    }

    private var frame: some View {
        VStack(spacing: 6) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<columns, id: \.self) { column in
                        cell(row * columns + column)
                    }
                }
            }
        }
    }

    private func cell(_ index: Int) -> some View {
        let isFilled = shown.frame.filled.contains(index)
        let isEmpty = shown.frame.empty.contains(index)
        return RoundedRectangle(cornerRadius: 6)
            .fill(isFilled ? Palette.dot : Palette.card)
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(Palette.ink, lineWidth: isEmpty && shown.areSpacesShown ? 4 : 2))
            .frame(width: 34, height: 34)
            .opacity(isEmpty && shown.areSpacesShown ? 1 : 0.85)
    }

    private var baskets: some View {
        HStack(spacing: 16) {
            ForEach(Array(shown.baskets.enumerated()), id: \.offset) { _, basket in
                VStack(spacing: 4) {
                    Image(systemName: ChromeCatalog.activitySymbolName(.tenFrameSplit))
                        .font(.title3)
                        .foregroundStyle(Palette.ink)
                    Text(String(basket.count))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                }
                .padding(10)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var showsEquation: Bool {
        shown.kind != .pickBaskets
    }

    private static let plus = String(Character(UnicodeScalar(43)))
    private static let equals = String(Character(UnicodeScalar(61)))

    private var equation: some View {
        HStack(spacing: 8) {
            part(shown.equation.first)
            Text(Self.plus)
            part(shown.equation.second)
            Text(Self.equals)
            part(shown.equation.total)
        }
        .font(.title2.weight(.semibold))
        .foregroundStyle(Palette.ink)
    }

    private func part(_ value: Int?) -> some View {
        Text(value.map { String($0) } ?? "?")
            .frame(minWidth: 34, minHeight: 34)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 8))
    }

    private func worked(_ moved: Int) -> some View {
        let parts = [shown.equation.first, shown.equation.second].compactMap { $0 }
        return HStack(spacing: 8) {
            Text(String(shown.targetTotal))
                .font(.headline)
            Text(Self.equals)
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index > 0 { Text(Self.plus) }
                Text(String(part))
                    .opacity(index == moved ? 0.9 : 1)
                    .padding(.horizontal, 6)
            }
        }
        .font(.headline)
        .foregroundStyle(Palette.ink)
    }

    private var summary: String {
        let filled = shown.frame.filled.count
        let empty = shown.frame.empty.count
        return "\(filled) + \(empty) = \(shown.targetTotal)"
    }
}
