import SwiftUI
import Core

/// The A4 rhythm level: a program strip of sound and rest slots, a call and a contrasting answer.
struct MusicA4View: View {
    let app: AppViewModel
    let language: Language
    let onDone: () -> Void
    @State private var strip = MusicA4.makeStrip(slotCount: MusicA4.slotCount)
    @State private var played: [MusicBeat] = []

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
            ForEach(0..<strip.board.slots.count, id: \.self) { index in
                let beat = index < strip.cards.count ? strip.cards[index] : nil
                Image(systemName: beat?.symbolName ?? RobotText.emptySlotSymbol)
                    .font(.title2)
                    .frame(width: 56, height: 56)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel(beat.map { TextTable.string("music.a4.beat.\($0.rawValue)", language) }
                                        ?? TextTable.string("music.a4.beat.empty", language))
            }
        }
    }

    private var palette: some View {
        HStack(spacing: 12) {
            ForEach(MusicBeat.allCases, id: \.self) { beat in
                RobotIconButton(symbol: beat.symbolName,
                                label: TextTable.string("music.a4.beat.\(beat.rawValue)", language),
                                side: 56) { strip.add(beat) }
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            RobotIconButton(symbol: RobotText.playSymbol, label: TextTable.string("music.a4.play", language),
                            side: 56) { strip.rewind(); played = strip.play() }
            Button { strip = MusicA4.expanding(strip) } label: {
                Text(verbatim: String(MusicA4.expandedSlotCount)).frame(width: 56, height: 56)
            }
            .accessibilityLabel(TextTable.string("music.a4.expand", language))
            RobotIconButton(symbol: ChromeCatalog.symbolName(for: .check),
                            label: TextTable.string("music.a4.save", language), side: 56) {
                app.saveMusicPattern(MusicA4Pattern(events: MusicA4.events(for: strip)))
                onDone()
            }
        }
    }
}
