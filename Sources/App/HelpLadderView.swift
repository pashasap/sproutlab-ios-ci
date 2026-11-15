import SwiftUI
import Core

/// The help ladder rungs revealed so far, each from its Core presentation (symbol, colour, text).
struct HelpLadderView: View {
    let steps: [HelpStepPresentation]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                HStack(spacing: 8) {
                    ForEach(step.symbolNames, id: \.self) { name in
                        Image(systemName: name)
                            .foregroundStyle(Palette.token(step.colourTokens.first ?? ""))
                            .accessibilityHidden(true)
                    }
                    Text(step.text).font(.headline).foregroundStyle(Palette.ink)
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
