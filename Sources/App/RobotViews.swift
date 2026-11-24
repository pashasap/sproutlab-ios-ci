import SwiftUI
import Core

/// Thin views over the robot rounds in Core. Arrows and icons only; no reading or typing.
struct RobotGridView: View {
    let world: GridWorld
    let robot: GridPoint

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<world.height, id: \.self) { y in
                HStack(spacing: 4) {
                    ForEach(0..<world.width, id: \.self) { x in cell(GridPoint(x, y)) }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func symbol(_ point: GridPoint) -> String {
        if point == robot { return RobotText.robotSymbol }
        if world.rocks.contains(point) { return RobotText.rockSymbol }
        return point == world.goal ? RobotText.goalSymbol : RobotText.emptyCellSymbol
    }

    private func cell(_ point: GridPoint) -> some View {
        Image(systemName: symbol(point))
            .frame(width: 44, height: 44)
            .foregroundStyle(point == world.goal ? Palette.accent : Palette.ink)
            .background(Palette.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct RobotIconButton: View {
    let symbol: String
    let label: String
    let side: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2)
                .frame(width: side, height: side)
                .background(Palette.accent.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel(label)
    }
}

struct RobotPredictionRow: View {
    let choices: [GridPoint]
    let language: Language
    let onPick: (GridPoint) -> Void

    var body: some View {
        HStack {
            ForEach(choices, id: \.self) { point in
                let name = RobotText.cellLabel(point)
                Button { onPick(point) } label: {
                    Text(verbatim: name)
                        .frame(minWidth: RobotLayout.slotSide, minHeight: RobotLayout.slotSide)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(TextTable.string("robot.choose.cell", language))
            }
        }
    }
}

/// An arrow drawn in a bordered card; fill and stroke come from the Core card style.
struct RobotArrowCard: View {
    let symbol: String
    let side: Double
    var style: RobotCardStyle = .standard

    private func colour(_ token: String) -> Color {
        token == "card" ? Palette.card : Palette.accent
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.title2)
            .foregroundStyle(Palette.ink)
            .frame(width: side, height: side)
            .background(colour(style.fill), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(colour(style.stroke), lineWidth: 2))
    }
}

struct RobotC1View: View {
    let language: Language
    let onDone: () -> Void
    @State private var round: RobotC1Round

    init(seed: UInt64, language: Language, onDone: @escaping () -> Void) {
        let audit = ProcessInfo.processInfo.arguments.contains("-auditStop")
        _round = State(initialValue: audit ? RobotC1Round.auditStop(seed: seed)
                       : RobotC1Round(presentation: RobotC1Presentation.make(seed: seed)))
        self.language = language
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 16) {
            RobotGridView(world: round.presentation.world, robot: round.position)
            HStack { ForEach(Array(round.presentation.cards.enumerated()), id: \.offset) { _, move in
                RobotArrowCard(symbol: RobotText.arrow(move), side: RobotLayout.slotSide,
                               style: round.presentation.cardStyle ?? .standard)
            } }
            RobotPredictionRow(choices: round.predictionChoices, language: language) { round.predict($0) }
            HStack {
                RobotIconButton(symbol: RobotText.stepSymbol, label: TextTable.string("robot.step", language),
                                side: RobotLayout.slotSide) { _ = round.step() }
                RobotIconButton(symbol: RobotText.playSymbol, label: TextTable.string("robot.play", language),
                                side: RobotLayout.slotSide) { round.play(); if round.isComplete { onDone() } }
                    .disabled(!round.playEnabled)
            }
        }
    }
}

struct RobotC2View: View {
    let language: Language
    let onDone: () -> Void
    @State private var round: RobotC2Round

    init(seed: UInt64, language: Language, onDone: @escaping () -> Void) {
        let item = RobotC2Presentation.make(seed: seed)
        _round = State(initialValue: RobotC2Round(world: item.world, slotCount: item.slotCount))
        self.language = language
        self.onDone = onDone
    }

    private func slot(_ index: Int) -> String {
        index < round.program.count ? RobotText.arrow(round.program[index]) : RobotText.emptySlotSymbol
    }

    var body: some View {
        VStack(spacing: 16) {
            RobotGridView(world: round.world, robot: round.position)
            HStack { ForEach(0..<round.slotCount, id: \.self) { index in
                Image(systemName: slot(index)).frame(width: RobotLayout.slotSide, height: RobotLayout.slotSide)
            } }
            HStack { ForEach(round.palette, id: \.self) { move in
                RobotIconButton(symbol: RobotText.arrow(move), label: RobotText.label(move, language),
                                side: RobotLayout.paletteSide) { round.add(move) }
            } }
            RobotPredictionRow(choices: round.isFull ? [round.world.goal] : [], language: language) {
                round.predict($0)
            }
            RobotIconButton(symbol: RobotText.playSymbol, label: TextTable.string("robot.play", language),
                            side: RobotLayout.slotSide) { round.play(); if round.isComplete { onDone() } }
                .disabled(!round.playEnabled)
        }
    }
}

struct RobotC3View: View {
    let language: Language
    let onDone: () -> Void
    @State private var round: RobotC3Round
    @State private var selected: Int?

    init(seed: UInt64, language: Language, onDone: @escaping () -> Void) {
        _round = State(initialValue: RobotC3Round(presentation: RobotC3Presentation.make(seed: seed)))
        self.language = language
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 16) {
            RobotGridView(world: round.presentation.world, robot: round.presentation.world.start)
            HStack { ForEach(Array(round.cards.enumerated()), id: \.offset) { index, move in
                VStack {
                    if round.markerIndex == index {
                        Image(systemName: RobotText.markerSymbol)
                            .accessibilityLabel(TextTable.string("robot.marker", language))
                    }
                    RobotArrowCard(symbol: RobotText.arrow(move), side: RobotLayout.slotSide)
                        .onTapGesture { selected = index }
                }
            } }
            HStack { ForEach(round.presentation.swapPalette, id: \.self) { move in
                RobotIconButton(symbol: RobotText.arrow(move), label: RobotText.label(move, language),
                                side: round.presentation.paletteSide) {
                    if let target = selected ?? round.markerIndex { round.swap(index: target, to: move) }
                }
            } }
            RobotIconButton(symbol: RobotText.playSymbol, label: TextTable.string("robot.play", language),
                            side: RobotLayout.slotSide) { round.play(); if round.isComplete { onDone() } }
        }
    }
}

struct RobotC4View: View {
    let language: Language
    let onDone: () -> Void
    @State private var round: RobotC4Round
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(seed: UInt64, language: Language, onDone: @escaping () -> Void) {
        let presentation = RobotC4Presentation.make(round: Int(seed % 4) + 1, seed: seed)
        _round = State(initialValue: RobotC4Round(presentation: presentation))
        self.language = language
        self.onDone = onDone
    }

    private var presentation: RobotC4Presentation { round.presentation }

    private func arrows(_ moves: [GridMove], side: Double) -> some View {
        ForEach(Array(moves.enumerated()), id: \.offset) { _, move in
            RobotArrowCard(symbol: RobotText.arrow(move), side: side)
        }
    }

    /// Plain arrow cards, then the boxed repeat block wrapping its arrows with the xN badge.
    private var programStrip: some View {
        let block = presentation.repeatBlock
        return HStack(spacing: 8) {
            arrows(presentation.plainBefore, side: RobotLayout.slotSide)
            HStack(spacing: 4) {
                Image(systemName: TextTable.string(block.iconId, .en))
                arrows(block.arrows, side: RobotLayout.slotSide)
                Text(verbatim: block.badge).font(.title3.bold())
            }
            .padding(6)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.accent, lineWidth: 3))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(TextTable.string(block.iconId + ".label", language) + " " + block.badge)
        }
        .accessibilityIgnoresInvertColors()
    }

    private var expandedPreview: some View {
        HStack(spacing: 2) { arrows(RobotC4PairView(presentation: presentation).expandedProgram, side: 24) }
            .accessibilityHidden(true)
            .accessibilityIgnoresInvertColors()
    }

    var body: some View {
        VStack(spacing: 16) {
            RobotGridView(world: presentation.world, robot: round.robotPosition)
                .accessibilityIgnoresInvertColors()
            programStrip
            expandedPreview
            repeatDots
            RobotPredictionRow(choices: round.predictionChoices, language: language) {
                round.submit($0)
                if round.isComplete { onDone() }
            }
            if !presentation.isPredictRound {
                RobotIconButton(symbol: RobotText.playSymbol, label: TextTable.string("robot.play", language),
                                side: RobotLayout.slotSide) { round.play(); if round.isComplete { onDone() } }
            }
        }
        .animation(reduceMotion ? nil : .default, value: round.robotPosition)
    }

    private var repeatDots: some View {
        let controls = RepeatControlsPresentation.standard
        return HStack {
            ForEach(controls.dotCounts, id: \.self) { count in
                Button { round.setRepeatCount(count) } label: {
                    Text(verbatim: String(count))
                        .frame(minWidth: controls.minDotSide, minHeight: controls.minDotSide)
                        .background(count == round.repeatCount ? Palette.accent.opacity(0.3) : Palette.card, in: Circle())
                }
                .accessibilityLabel(controls.accessibleName(count: count, language))
            }
        }
    }
}

struct RobotRoundView: View {
    let round: RoundViewModel
    let language: Language

    var body: some View {
        let seed = round.robotSeed
        VStack(spacing: 16) {
            Text(verbatim: TextTable.string("robot.look.robot", language)).font(.title3)
            switch round.robotKind {
            case "robot.C1": RobotC1View(seed: seed, language: language) { round.finishRobotQuestion() }
            case "robot.C2": RobotC2View(seed: seed, language: language) { round.finishRobotQuestion() }
            case "robot.C4": RobotC4View(seed: seed, language: language) { round.finishRobotQuestion() }
            default: RobotC3View(seed: seed, language: language) { round.finishRobotQuestion() }
            }
        }
        .id(round.questionNumber)
        .padding(24)
    }
}
