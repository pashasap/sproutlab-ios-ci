import SwiftUI
import Core

/// The sentence question: the sentence with its one blank, exactly three word choices, a Tap to Hear
/// control that speaks the whole sentence only on tap, and the three help steps.
/// Every value it draws comes from `SentenceQuestion`; the view holds no state of its own.
struct SentenceQuestionView: View {
    let question: SentenceQuestion
    let language: Language
    let actions: Actions

    /// The two things a tap can do here; nothing is spoken unless `hear` is called.
    struct Actions {
        let answer: (Int) -> Void
        let hear: () -> Void
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(question.promptText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)
            sentenceLine
            helpSteps
            choiceButtons
            hearButton
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    /// The words in reading order; the missing word is drawn as the blank slot.
    private var sentenceLine: some View {
        Text(question.words.joined(separator: " "))
            .font(.system(size: 30, weight: .semibold, design: .rounded))
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(question.words.joined(separator: " "))
            .accessibilityValue(question.blankLabel)
            .accessibilityIdentifier(SproutIdentifier.stimulus)
    }

    private var helpSteps: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(question.helpSteps.enumerated()), id: \.offset) { _, step in
                Text(step.text)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(step.text)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var choiceButtons: some View {
        HStack(spacing: 16) {
            ForEach(Array(question.choices.enumerated()), id: \.offset) { index, label in
                Button { actions.answer(index) } label: {
                    Text(label)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: Touch.minimumPoints)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel(TextTable.string("a11y.choice", language))
                .accessibilityValue(label)
                .accessibilityIdentifier(SproutIdentifier.choice(index))
            }
        }
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
