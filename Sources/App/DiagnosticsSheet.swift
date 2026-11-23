import SwiftUI
import Core

struct DiagnosticsSheet: View {
    let model: DiagnosticsModel
    let language: Language
    let app: AppViewModel
    @State private var confirmReset = false
    @Environment(\.dismiss) private var dismiss
    @State private var showGallery = false

    var body: some View {
        VStack(spacing: 16) {
            Text(TextTable.string("settings.diagnostics", language))
                .font(.title2.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(rows, id: \.key) { row in
                        HStack {
                            Text(TextTable.string(row.key, language))
                            Spacer()
                            Text(verbatim: row.value).monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            developerControls
            Button { showGallery = true } label: {
                Text(TextTable.string("gallery.open", language))
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(minHeight: galleryControl.height)
            .accessibilityIdentifier(galleryControl.accessibilityId)
            Button { dismiss() } label: {
                Text(TextTable.string("diag.close", language))
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .sheet(isPresented: $showGallery) {
            GalleryView(language: language)
        }
        .alert(TextTable.string("diag.reset.title", language), isPresented: $confirmReset) {
            Button(TextTable.string("diag.reset.cancel", language), role: .cancel) {
                app.resetAllProgress(confirmed: false)
            }
            Button(TextTable.string("diag.reset.confirm", language), role: .destructive) {
                app.resetAllProgress(confirmed: true)
            }
        } message: {
            Text(TextTable.string("diag.reset.message", language))
        }
        .foregroundStyle(Palette.ink)
        .padding(24)
        .background(Palette.background.ignoresSafeArea())
    }

    @ViewBuilder private var developerControls: some View {
        Toggle(TextTable.string("diag.developer", language),
               isOn: Binding(get: { app.developerMode }, set: { app.setDeveloperMode($0) }))
            .accessibilityIdentifier("diag.developer")
        Button(role: .destructive) { confirmReset = true } label: {
            Text(TextTable.string("diag.reset", language))
        }
        .accessibilityIdentifier("diag.reset")
    }

    private var galleryControl: TerrariumControl { DiagnosticsScreen.forAuditStop().galleryButton }

    private var rows: [(key: String, value: String)] {
        [("diag.version", model.versionText), ("diag.build", model.buildText),
         ("diag.launch", model.launchTimeText), ("diag.frames", model.droppedFramesText),
         ("diag.save", model.lastSaveText), ("diag.audio", model.audioStateText),
         ("diag.voice.fr", model.frenchVoiceText), ("diag.voice.en", model.englishVoiceText)]
            + model.droppedFrameRows.map { (key: $0.labelKey, value: String($0.count)) }
    }
}
