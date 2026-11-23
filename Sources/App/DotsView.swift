import SwiftUI
import Core

/// Renders a Core `StimulusPresentation` as is: dots, crossed-out dots, a ten-frame or a number track.
/// The wrong-answer cue from Core outlines the dots or the empty slots (static, no animation).
struct DotsView: View {
    let presentation: StimulusPresentation
    var cue: CueTarget?
    var isComparison = false

    var body: some View {
        if isComparison, presentation.groups.count == 2 {
            comparisonCards
        } else {
            plainBody
        }
    }

    /// Two cards side by side, their dots placed by Core `comparisonLayout`.
    private var comparisonCards: some View {
        let width = Double(UIScreen.main.bounds.width) - 48
        let screen = ScreenMetrics(width: width, height: 300,
                                   insets: SafeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        let layout = LayoutPolicy.comparisonLayout(screen, leftCount: presentation.groups[0].count,
                                                   rightCount: presentation.groups[1].count)
        return ZStack(alignment: .topLeading) {
            card(layout.leftCard, layout.leftDots)
            card(layout.rightCard, layout.rightDots)
        }
        .offset(y: -layout.leftCard.y)
        .frame(width: width, height: layout.leftCard.height, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
    }

    private func card(_ rect: LayoutRect, _ dots: [LayoutRect]) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.locked, lineWidth: 2)
                .frame(width: rect.width, height: rect.height)
                .offset(x: rect.x, y: rect.y)
            ForEach(dots.indices, id: \.self) { index in
                Circle().fill(dotColour).frame(width: dots[index].width, height: dots[index].height)
                    .offset(x: dots[index].x, y: dots[index].y)
            }
        }
    }

    private var plainBody: some View {
        GeometryReader { proxy in
            let layout = LayoutPolicy.stimulusLayout(presentation, availableWidth: Double(proxy.size.width))
            laidOut(layout)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: Double(heightFor(width: UIScreen.main.bounds.width)))
        .accessibilityElement(children: .ignore)
    }

    private func heightFor(width: CGFloat) -> CGFloat {
        let layout = LayoutPolicy.stimulusLayout(presentation, availableWidth: Double(width) - 48)
        return CGFloat(layout.totalHeight) + (presentation.isTenFrame ? 20 : 0)
    }

    private func laidOut(_ layout: StimulusLayout) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(layout.placements, id: \.index) { placement in
                marker(presentation.positions[placement.index].shape, value: value(at: placement.index))
                    .frame(width: layout.dotSize, height: layout.dotSize)
                    .offset(x: Double(placement.column) * layout.pitch, y: Double(placement.row) * layout.pitch)
            }
        }
        .frame(width: layout.totalWidth, height: layout.totalHeight, alignment: .topLeading)
        .padding(presentation.isTenFrame ? 10 : 0)
        .overlay {
            if presentation.isTenFrame {
                RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.locked, lineWidth: 2)
            }
        }
    }

    private func value(at index: Int) -> Int? {
        presentation.trackValues.indices.contains(index) ? presentation.trackValues[index] : nil
    }

    private var dotColour: Color { Palette.token(presentation.dotColourToken) }
    private var markColour: Color { Palette.token(presentation.markColourToken) }

    @ViewBuilder
    private func marker(_ shape: StimulusShape, value: Int?) -> some View {
        let cued = cue == (shape == .filled ? .dots : .emptySlots)
        if !presentation.trackValues.isEmpty {
            trackCell(shape, value: value, cued: cued)
        } else {
            dot(shape, cued: cued)
        }
    }

    @ViewBuilder
    private func dot(_ shape: StimulusShape, cued: Bool) -> some View {
        switch shape {
        case .filled:
            Circle().fill(dotColour).frame(width: 28, height: 28).overlay { ring(cued) }
        case .emptyOutline:
            Circle().strokeBorder(dotColour, lineWidth: cued ? 6 : 3).frame(width: 28, height: 28)
                .overlay { ring(cued) }
        case .crossedOut:
            Circle().fill(dotColour).frame(width: 28, height: 28)
                .overlay { crossMark }
                .overlay { Circle().strokeBorder(markColour, lineWidth: 3) }
        }
    }

    /// A number-track slot: the number inside a rounded square, or an outlined empty square.
    @ViewBuilder
    private func trackCell(_ shape: StimulusShape, value: Int?, cued: Bool) -> some View {
        let box = RoundedRectangle(cornerRadius: 10)
        if shape == .emptyOutline {
            box.strokeBorder(dotColour, lineWidth: cued ? 6 : 3).frame(width: 48, height: 48)
        } else {
            box.fill(Palette.card).frame(width: 48, height: 48)
                .overlay { box.strokeBorder(markColour, lineWidth: 2) }
                .overlay { Text(value.map(String.init) ?? "").font(.title3.weight(.bold)).foregroundStyle(markColour) }
        }
    }

    /// Contrasting cross (mark colour over a halo), never a thin line in the dot's own colour.
    private var crossMark: some View {
        let halo = Palette.token(presentation.haloColourToken)
        return ZStack {
            Capsule().fill(halo).frame(width: 30, height: 8).rotationEffect(.degrees(45))
            Capsule().fill(halo).frame(width: 30, height: 8).rotationEffect(.degrees(-45))
            Capsule().fill(markColour).frame(width: 26, height: 4).rotationEffect(.degrees(45))
            Capsule().fill(markColour).frame(width: 26, height: 4).rotationEffect(.degrees(-45))
        }
    }

    @ViewBuilder
    private func ring(_ cued: Bool) -> some View {
        if cued {
            Circle().strokeBorder(markColour, lineWidth: 2).padding(-5)
        }
    }
}
