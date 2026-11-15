import SwiftUI
import Core

/// Hosts the round view model; shows nothing when there is no active round.
struct RoundScreen: View {
    let app: AppViewModel

    var body: some View {
        if let round = app.round {
            RoundView(app: app, round: round)
        }
    }
}

struct RoundView: View {
    let app: AppViewModel
    let round: RoundViewModel

    var body: some View {
        GeometryReader { proxy in
            let wide = LayoutPolicy.usesSideBySide(width: proxy.size.width)
            ScrollView {
                VStack(spacing: 24) {
                    backButton
                    progress
                    promptAndHelper(wide: wide)
                    if round.kitPresentation != nil {
                        ReadingKitHost(round: round, language: app.language)
                    } else {
                        choices
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var backButton: some View {
        let back = ChromeCatalog.roundBack
        return HStack {
            Button { round.abandonRound() } label: {
                Image(systemName: back.symbolName)
                    .font(.system(size: back.pointSize))
                    .foregroundStyle(Palette.accent)
                    .frame(minWidth: back.hitArea, minHeight: back.hitArea)
            }
            .accessibilityLabel(TextTable.string("icon.back.label", app.language))
            .accessibilityIdentifier(SproutIdentifier.back)
            Spacer()
        }
    }

    private var progress: some View {
        Text(AccessibilityText.questionAnnouncement(
            number: round.questionNumber, of: round.questionCount, language: app.language))
            .font(.headline)
            .foregroundStyle(Palette.locked)
    }

    @ViewBuilder
    private func promptAndHelper(wide: Bool) -> some View {
        let layout = wide ? AnyLayout(HStackLayout(alignment: .top, spacing: 24))
                          : AnyLayout(VStackLayout(spacing: 16))
        layout {
            promptCard
            stimulusCard
        }
    }

    private var promptCard: some View {
        VStack(spacing: 16) {
            PromptView(identity: round.identity, language: app.language)
            Button { speak() } label: {
                Image(systemName: ChromeCatalog.symbolName(for: .ear))
                    .font(.title2)
                    .frame(minWidth: Touch.minimumPoints, minHeight: Touch.minimumPoints)
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel(TextTable.string("a11y.speak", app.language))
            .accessibilityIdentifier(SproutIdentifier.listen)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    /// A kit item speaks its own syllable or word; every other item speaks the prompt.
    private func speak() {
        if round.kitPresentation != nil { app.hear() } else { app.listen() }
    }

    private var stimulusCard: some View {
        VStack(spacing: 12) {
            if let text = round.feedbackText {
                Text(text)
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
            }
            let presentation = round.stimulus.presentation
            DotsView(presentation: presentation, cue: round.wrongCue?.target)
                .accessibilityLabel(TextTable.string("a11y.dots", app.language))
                .accessibilityValue(round.stimulus.presentation.accessibilityValue(app.language))
                .accessibilityIdentifier(SproutIdentifier.stimulus)
            HelpLadderView(steps: Array(round.helpLadder.prefix(round.revealedHelpSteps)))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private var choices: some View {
        let number = round.questionNumber
        let dimmed = round.wrongCue?.dimmedChoices ?? []
        return HStack(spacing: 16) {
            ForEach(Array(round.choiceLabels.enumerated()), id: \.offset) { index, label in
                Button { round.select(choiceIndex: index, questionNumber: number) } label: {
                    Text(label)
                }
                .buttonStyle(PrimaryButtonStyle())
                .opacity(dimmed.contains(index) ? 0.35 : 1)
                .accessibilityLabel(TextTable.string("a11y.choice", app.language))
                .accessibilityValue(label)
                .accessibilityIdentifier(SproutIdentifier.choice(index))
            }
        }
    }
}
