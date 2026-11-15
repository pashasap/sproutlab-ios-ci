import SwiftUI
import Core

struct DiagnosticsSheet: View {
    let model: DiagnosticsModel
    let language: Language
    @Environment(\.dismiss) private var dismiss
    @State private var showGallery = false

    var body: some View {
        VStack(spacing: 16) {
            Text(TextTable.string("settings.diagnostics", language))
                .font(.title2.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            ForEach(rows, id: \.key) { row in
                HStack {
                    Text(TextTable.string(row.key, language))
                    Spacer()
                    Text(verbatim: row.value).monospacedDigit()
                }
                .accessibilityElement(children: .combine)
            }
            Button { showGallery = true } label: {
                Text(TextTable.string("gallery.open", language))
            }
            .buttonStyle(PrimaryButtonStyle())
            Button { dismiss() } label: {
                Text(TextTable.string("diag.close", language))
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .sheet(isPresented: $showGallery) {
            GalleryView(language: language)
        }
        .foregroundStyle(Palette.ink)
        .padding(24)
        .background(Palette.background.ignoresSafeArea())
    }

    private var rows: [(key: String, value: String)] {
        [("diag.version", model.versionText), ("diag.build", model.buildText),
         ("diag.launch", model.launchTimeText), ("diag.frames", model.droppedFramesText),
         ("diag.save", model.lastSaveText), ("diag.audio", model.audioStateText),
         ("diag.voice.fr", model.frenchVoiceText), ("diag.voice.en", model.englishVoiceText)]
            + model.droppedFrameRows.map { (key: $0.labelKey, value: String($0.count)) }
    }
}
