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
            rowsList
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

    /// Label and value side by side; stacked when the text no longer fits (accessibility sizes).
    private var rowsList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(rows, id: \.key) { row in
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Text(TextTable.string(row.key, language))
                            Spacer()
                            valueText(row.key, row.value)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(TextTable.string(row.key, language))
                            valueText(row.key, row.value)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder private var developerControls: some View {
        let row = DiagnosticsScreen.developerRow(isOn: app.developerMode, language: language)
        Button { app.setDeveloperMode(!app.developerMode) } label: {
            HStack {
                Text(row.label)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: row.symbolName)
                    Text(verbatim: row.valueText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Palette.ink.opacity(0.12)))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: row.minHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(row.label)
        .accessibilityValue(row.valueText)
        .accessibilityIdentifier(row.accessibilityId)
        Button(role: .destructive) { confirmReset = true } label: {
            Text(TextTable.string("diag.reset", language))
        }
        .accessibilityIdentifier("diag.reset")
    }

    @ViewBuilder private func valueText(_ key: String, _ value: String) -> some View {
        if key == "diag.version" || key.hasPrefix("diag.voice") {
            Text(verbatim: value).monospacedDigit().textSelection(.enabled)
        } else {
            Text(verbatim: value).monospacedDigit()
        }
    }

    private var galleryControl: TerrariumControl { DiagnosticsScreen.forAuditStop().galleryButton }

    private var rows: [(key: String, value: String)] {
        var result: [(key: String, value: String)] = [
            ("diag.version", model.versionText), ("diag.build", model.buildText),
            ("diag.launch", model.launchTimeText), ("diag.frames", model.droppedFramesText),
            ("diag.save", model.lastSaveText), ("diag.audio", model.audioStateText),
            ("diag.voice.fr", model.frenchVoiceText), ("diag.voice.en", model.englishVoiceText),
            ("diag.voice.active", model.voiceRowText)]
        if let hint = model.voiceHintText { result.append((key: "diag.voice.hint", value: hint)) }
        return result + model.droppedFrameRows.map { (key: $0.labelKey, value: String($0.count)) }
    }
}
