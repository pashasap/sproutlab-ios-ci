import Foundation

public enum AudioEngineState: Equatable, Sendable {
    case stopped
    case running
    case error
}

public protocol DiagnosticsSource: Sendable {
    var version: String { get }
    var build: String { get }
    var launchSeconds: Double { get }
    var droppedFrames: Int { get }
    var lastSave: SaveReport? { get }
    var audioEngine: AudioEngineState { get }
    var frenchVoiceName: String? { get }
    var englishVoiceName: String? { get }
}

/// The lowest iOS / iPadOS version the app supports (the manifests carry the same floor).
public enum PlatformFloor {
    public static let minimumOS = "27.0"
}

/// How long the title must be held before the diagnostics open.
public enum TitleHold {
    public static let threshold: Double = 3.0

    public static func isLongEnough(held: Double) -> Bool {
        held >= threshold
    }
}

public enum DroppedFrameSurface: String, CaseIterable, Sendable {
    case terrarium, gallery
}

public struct DroppedFrameRow: Equatable, Sendable {
    public var surface: DroppedFrameSurface
    public var phase: DayPhase
    public var count: Int
    public var labelKey: String
}

/// Dropped-frame counts per surface and phase.
@MainActor
public final class DroppedFrameCounter {
    private var counts: [String: Int] = [:]

    public init() {}

    static func key(_ surface: DroppedFrameSurface, _ phase: DayPhase) -> String {
        "diag.frames.\(surface.rawValue).\(phase.rawValue)"
    }

    public func record(_ surface: DroppedFrameSurface, _ phase: DayPhase, count: Int) {
        counts[Self.key(surface, phase), default: 0] += max(count, 0)
    }

    public func count(_ surface: DroppedFrameSurface, _ phase: DayPhase) -> Int {
        counts[Self.key(surface, phase)] ?? 0
    }
}

/// Formats the measurements of a `DiagnosticsSource`, reading it live on every access.
@MainActor
public struct DiagnosticsModel {
    private let source: any DiagnosticsSource
    private let frames: DroppedFrameCounter

    public init(source: any DiagnosticsSource, frames: DroppedFrameCounter = DroppedFrameCounter()) {
        self.source = source
        self.frames = frames
    }

    /// 8 rows: surface-major, then phase order.
    public var droppedFrameRows: [DroppedFrameRow] {
        DroppedFrameSurface.allCases.flatMap { surface in
            DayPhase.allCases.map { phase in
                DroppedFrameRow(surface: surface, phase: phase, count: frames.count(surface, phase),
                                labelKey: DroppedFrameCounter.key(surface, phase))
            }
        }
    }

    public var versionText: String { source.version }
    public var buildText: String { source.build }

    public var launchTimeText: String {
        String(format: "%.2f s", locale: Locale(identifier: "en_US_POSIX"), source.launchSeconds)
    }

    public var droppedFramesText: String { String(source.droppedFrames) }

    public var minimumOSText: String { PlatformFloor.minimumOS }

    public var lastSaveText: String {
        guard let report = source.lastSave else { return "No save yet" }
        guard report.success else { return "Failed" }
        let style = Date.FormatStyle(date: .omitted, time: .standard)
            .locale(Locale(identifier: "en_US_POSIX"))
        return "OK \(report.time.formatted(style))"
    }

    public var audioStateText: String {
        switch source.audioEngine {
        case .stopped: return "Stopped"
        case .running: return "Running"
        case .error: return "Error"
        }
    }

    public var frenchVoiceText: String { source.frenchVoiceName ?? "Not available" }
    public var englishVoiceText: String { source.englishVoiceName ?? "Not available" }
}
