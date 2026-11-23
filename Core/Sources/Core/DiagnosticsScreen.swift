import Foundation

public struct DiagnosticsMeasurement: Equatable, Sendable {
    public let labelKey: String
    public let value: String
}

/// What the diagnostics view draws at the audit stop: static measurements and the gallery button.
public struct DiagnosticsScreen: Equatable, Sendable {
    public let measurements: [DiagnosticsMeasurement]
    public let galleryButton: TerrariumControl
    /// The diagnostics read their source once; no repeating timer is needed.
    public let requiresTimer: Bool

    @MainActor
    public static func forAuditStop() -> DiagnosticsScreen {
        let model = DiagnosticsModel(source: AuditDiagnosticsSource())
        return DiagnosticsScreen(
            measurements: [
                DiagnosticsMeasurement(labelKey: "diag.version", value: model.versionText),
                DiagnosticsMeasurement(labelKey: "diag.build", value: model.buildText),
                DiagnosticsMeasurement(labelKey: "diag.launch", value: model.launchTimeText),
                DiagnosticsMeasurement(labelKey: "diag.frames", value: model.droppedFramesText),
                DiagnosticsMeasurement(labelKey: "diag.save", value: model.lastSaveText),
                DiagnosticsMeasurement(labelKey: "diag.audio", value: model.audioStateText)
            ],
            galleryButton: TerrariumControl(accessibilityId: "sproutlab.diagnostics.gallery",
                                            iconKey: "icon.journal", labelKey: "gallery.open", side: 56),
            requiresTimer: false)
    }
}

struct AuditDiagnosticsSource: DiagnosticsSource {
    var version: String { "1.0" }
    var build: String { "1" }
    var launchSeconds: Double { 0.5 }
    var droppedFrames: Int { 0 }
    var lastSave: SaveReport? { nil }
    var audioEngine: AudioEngineState { .stopped }
    var frenchVoiceName: String? { nil }
    var englishVoiceName: String? { nil }
}
