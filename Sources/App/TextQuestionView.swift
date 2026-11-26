import SwiftUI
import Core

/// The text question: every sentence of the text, one prompt, exactly two choices, a Tap to Hear
/// control for the whole text and the three help steps. It draws the Core value and holds no state.
struct TextQuestionView: View {
    let screen: TextScreen
    let actions: Actions
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    struct Actions {
        let answer: (Int) -> Void
        let hear: () -> Void
        let revealHelp: (Int) -> Void
    }

    var body: some View {
        VStack(spacing: 16) {
            prompt
            sentences
            helpSteps
            choices
            hearButton
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private var prompt: some View {
        Text(screen.promptText)
            .font(.title3.weight(.semibold))
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
    }

    private var sentences: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(screen.sentences.enumerated()), id: \.offset) { index, words in
                Text(words.joined(separator: " "))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(screen.markedSentence == index ? Palette.accent.opacity(0.18) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityIdentifier(SproutIdentifier.stimulus)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var helpSteps: some View {
        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8))
                                                         : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            ForEach(Array(screen.helpSteps.enumerated()), id: \.offset) { index, step in
                helpButton(step, index: index)
            }
        }
    }

    private func helpButton(_ step: TextScreenHelpStep, index: Int) -> some View {
        let revealed = screen.revealedSteps.contains(index)
        return Button { actions.revealHelp(index) } label: {
            VStack(spacing: 4) {
                Image(systemName: step.iconName)
                    .foregroundStyle(Palette.accent)
                Text(step.accessibilityLabel)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(4)
            .frame(minWidth: Touch.minimumPoints, maxWidth: .infinity, minHeight: Touch.minimumPoints)
            .background(revealed ? Palette.accent.opacity(0.18) : Palette.background,
                        in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(step.accessibilityLabel)
        .accessibilityAddTraits(revealed ? .isSelected : [])
    }

    private var choices: some View {
        HStack(spacing: 16) {
            ForEach(Array(screen.choices.enumerated()), id: \.offset) { index, label in
                choiceButton(index: index, label: label)
            }
        }
    }

    private func choiceButton(index: Int, label: String) -> some View {
        Button { actions.answer(index) } label: {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text(label)
                    if screen.correctChoiceIndex == index, let name = screen.linkedName {
                        Text(name).underline()
                    }
                }
                if screen.correctChoiceIndex == index, let sentence = screen.evidenceText {
                    HStack(spacing: 6) {
                        Text(sentence)
                            .font(.footnote)
                        if let icon = screen.evidenceIconName {
                            Image(systemName: icon)
                        }
                    }
                }
            }
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: Touch.minimumPoints)
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityLabel(screen.choiceLabel)
        .accessibilityValue(label)
        .accessibilityIdentifier(SproutIdentifier.choice(index))
    }

    private var hearButton: some View {
        Button { actions.hear() } label: {
            Image(systemName: screen.hearIconName)
                .font(.title2)
                .frame(minWidth: Touch.minimumPoints, minHeight: Touch.minimumPoints)
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityLabel(screen.hearLabel)
        .accessibilityIdentifier(SproutIdentifier.listen)
    }
}
