import SwiftUI
import Core

/// The text question: every sentence of the text, one prompt, exactly two choices, a Tap to Hear
/// control for the whole text and the three help steps. It draws the Core value and holds no state.
struct TextQuestionView: View {
    let question: TextQuestion
    /// Help steps revealed so far; the ladder never changes the answer.
    let revealedSteps: Int
    let language: Language
    let actions: Actions

    struct Actions {
        let answer: (Int) -> Void
        let hear: () -> Void
    }

    private var help: TextHelp { question.help(step: revealedSteps) }

    var body: some View {
        VStack(spacing: 16) {
            prompt
            sentences
            choices
            hearButton
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private var prompt: some View {
        Text(question.promptText)
            .font(.title3.weight(.semibold))
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
    }

    private var sentences: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(question.sentences.enumerated()), id: \.offset) { index, words in
                Text(words.joined(separator: " "))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(help.markedSentence == index ? Palette.accent.opacity(0.18) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityIdentifier(SproutIdentifier.stimulus)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var choices: some View {
        HStack(spacing: 16) {
            ForEach(Array(question.choices.enumerated()), id: \.offset) { index, label in
                choiceButton(index: index, label: label)
            }
        }
    }

    private func choiceButton(index: Int, label: String) -> some View {
        Button { actions.answer(index) } label: {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text(label)
                    if help.linkedChoiceIndex == index, let name = help.linkedName {
                        Text(name).foregroundStyle(Palette.accent)
                    }
                }
                if help.evidenceChoiceIndex == index, let sentence = evidenceText {
                    HStack(spacing: 6) {
                        Text(sentence)
                            .font(.footnote)
                        if let icon = help.linkIcon {
                            Image(systemName: icon)
                        }
                    }
                }
            }
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: Touch.minimumPoints)
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityLabel(TextTable.string("a11y.choice", language))
        .accessibilityValue(label)
        .accessibilityIdentifier(SproutIdentifier.choice(index))
    }

    /// The marked sentence shown beside the right choice at the last ladder step.
    private var evidenceText: String? {
        guard let index = help.evidenceSentence, question.sentences.indices.contains(index) else { return nil }
        return question.sentences[index].joined(separator: " ")
    }

    private var hearButton: some View {
        Button { actions.hear() } label: {
            Image(systemName: ChromeCatalog.symbolName(for: .ear))
                .font(.title2)
                .frame(minWidth: Touch.minimumPoints, minHeight: Touch.minimumPoints)
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityLabel(question.hearLabel)
        .accessibilityIdentifier(SproutIdentifier.listen)
    }
}
