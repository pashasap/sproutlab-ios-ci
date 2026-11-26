import SwiftUI
import Core

/// Hosts the round view model; shows nothing when there is no active round.
struct RoundScreen: View {
    let app: AppViewModel

    var body: some View {
        if let round = app.round {
            if round.robotKind == "music.A4" {
                MusicA4View(app: app, language: app.language, seed: round.robotSeed) { round.finishRobotQuestion() }
                    .id(round.questionNumber)
            } else if round.robotKind != nil {
                RobotRoundView(round: round, language: app.language)
            } else {
                RoundView(app: app, round: round)
            }
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
                    } else if let question = round.sentenceQuestion {
                        SentenceQuestionView(question: question, language: app.language,
                                             actions: .init(
                                                answer: { round.select(choiceIndex: $0, questionNumber: round.questionNumber) },
                                                hear: { app.hearSentence(question) }))
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
        Text(AccessibilityText.progressLabel(
            number: round.questionNumber, of: round.questionCount, language: app.language))
            .font(.headline)
            .foregroundStyle(Palette.ink)
    }

    @ViewBuilder
    private func promptAndHelper(wide: Bool) -> some View {
        let layout = wide ? AnyLayout(HStackLayout(alignment: .top, spacing: 24))
                          : AnyLayout(VStackLayout(spacing: 16))
        layout {
            promptCard
            if round.showsStimulusCard { stimulusCard }
        }
    }

    private var promptCard: some View {
        VStack(spacing: 16) {
            PromptView(identity: round.identity, language: app.language,
                       englishText: round.readingPresentation?.promptText ?? "",
                       segments: round.m3Presentation == nil && round.m4Presentation == nil ? [] : round.promptSegments,
                       formula: round.m3Presentation == nil ? round.stimulus.presentation.formula : nil)
            if round.sentenceQuestion == nil {
                Button { speak() } label: {
                    Image(systemName: ChromeCatalog.symbolName(for: .ear))
                        .font(.title2)
                        .frame(minWidth: Touch.minimumPoints, minHeight: Touch.minimumPoints)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel(TextTable.string("a11y.speak", app.language))
                .accessibilityIdentifier(SproutIdentifier.listen)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    /// Tap to Hear: the only path that speaks; it says the full sentence line, never auto-spoken.
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
            if let word = round.readingPresentation?.stimulusWord, !word.isEmpty, round.kitPresentation == nil {
                Text(word)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .accessibilityIdentifier(SproutIdentifier.stimulus)
            }
            if let shown = round.m1Presentation {
                M1View(shown: shown, label: TextTable.string("a11y.dots", app.language))
            } else if let shown = round.m2Presentation {
                M2View(shown: shown, label: TextTable.string("a11y.dots", app.language))
            } else if let shown = round.m3Presentation {
                M3View(shown: shown, label: TextTable.string("a11y.dots", app.language), language: app.language)
            } else if let shown = round.m4Presentation {
                M4View(shown: shown, language: app.language)
            } else if round.readingPresentation == nil, round.sentenceQuestion == nil {
                let presentation = round.stimulus.presentation
                DotsView(presentation: presentation, cue: round.wrongCue?.target,
                         isComparison: round.identity == .comparison)
                    .accessibilityLabel(TextTable.string("a11y.dots", app.language))
                    .accessibilityValue(round.stimulus.presentation.accessibilityValue(app.language))
                    .accessibilityIdentifier(SproutIdentifier.stimulus)
            }
            HelpLadderView(steps: Array(round.helpLadder.prefix(round.revealedHelpSteps)))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private var choices: some View {
        let number = round.questionNumber
        let dimmed = round.wrongCue?.dimmedChoices ?? []
        // M1 numerals come from the Core presentation value, index-aligned with the item's choices.
        let m1Numerals = round.m1Presentation?.choices ?? []
        return HStack(spacing: 16) {
            ForEach(Array(round.choiceLabels.enumerated()), id: \.offset) { index, label in
                let reading = round.readingPresentation?.choices
                let shown = reading?.indices.contains(index) == true ? reading![index].text
                    : (m1Numerals.indices.contains(index) ? String(m1Numerals[index]) : label)
                Button { round.select(choiceIndex: index, questionNumber: number) } label: {
                    Text(shown)
                }
                .buttonStyle(PrimaryButtonStyle())
                .opacity(dimmed.contains(index) ? 0.35 : 1)
                .accessibilityLabel(reading?.indices.contains(index) == true
                                    ? reading![index].accessibilityLabel
                                    : TextTable.string("a11y.choice", app.language))
                .accessibilityValue(shown)
                .accessibilityIdentifier(SproutIdentifier.choice(index))
            }
        }
    }
}
