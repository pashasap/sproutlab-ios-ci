import SwiftUI
import Core

/// The A4 rhythm level: a seeded example strip of sound and rest slots, edited with a palette.
struct MusicA4View: View {
    let app: AppViewModel
    let language: Language
    let onDone: () -> Void
    @State private var round: MusicA4Round

    init(app: AppViewModel, language: Language, seed: UInt64, onDone: @escaping () -> Void) {
        self.app = app
        self.language = language
        self.onDone = onDone
        _round = State(initialValue: MusicA4Round(seed: seed))
    }

    private var presentation: MusicA4Presentation { round.presentation(language: language) }

    var body: some View {
        VStack(spacing: 16) {
            slotRow
            palette
            controls
        }
        .padding(24)
    }

    private var slotRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(presentation.slots.enumerated()), id: \.offset) { index, slot in
                Button { round.tapSlot(index) } label: {
                    Image(systemName: slot.symbolName)
                        .font(.title2)
                        .frame(width: 56, height: 56)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel(slot.accessibilityLabel)
            }
        }
    }

    private var palette: some View {
        HStack(spacing: 12) {
            ForEach(MusicBeat.allCases, id: \.self) { beat in
                RobotIconButton(symbol: beat.symbolName,
                                label: TextTable.string("music.a4.beat.\(beat.rawValue)", language),
                                side: 56) { round.selectPalette(beat) }
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            RobotIconButton(symbol: RobotText.playSymbol, label: TextTable.string("music.a4.play", language),
                            side: 56) { var strip = round.strip; _ = strip.play() }
            Button { round.expand() } label: {
                Text(verbatim: String(MusicA4.expandedSlotCount)).frame(width: 56, height: 56)
            }
            .accessibilityLabel(TextTable.string("music.a4.expand", language))
            RobotIconButton(symbol: ChromeCatalog.symbolName(for: .check),
                            label: TextTable.string("music.a4.save", language), side: 56) {
                app.saveMusicPattern(MusicA4Pattern(events: MusicA4.events(for: round.strip)))
                onDone()
            }
        }
    }
}
