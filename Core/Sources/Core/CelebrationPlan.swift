import Foundation

public enum CelebrationMotion: Equatable, Sendable {
    case gentle
    case `static`
}

/// The one reward moment of a completed round. It is the same for every round: it never depends on
/// how the round went, never gates the next-action buttons and never shows a missing star or a replay prompt.
public struct CelebrationPlan: Equatable, Sendable {
    public let stars: Int
    public let chimeCount: Int
    public let motionCount: Int
    public let glintCount: Int
    public let duration: Double
    public let actionsDelay: Double
    public let motion: CelebrationMotion
    public let missingStarOutlines: Int
    public let replayPrompt: Bool

    public static let maximumDuration: Double = 1.5

    /// The round entry is accepted so every caller passes a finished round; the plan ignores its details.
    public init(_ entry: RoundEntry, reduceMotion: Bool = false) {
        stars = ProgressRecord.starsPerRound
        chimeCount = 1
        motionCount = 1
        glintCount = 1
        duration = reduceMotion ? 0 : 1.2
        actionsDelay = 0
        motion = reduceMotion ? .static : .gentle
        missingStarOutlines = 0
        replayPrompt = false
    }

    public func text(_ language: Language) -> String {
        TextTable.string("celebration.text", language)
    }
}

/// The chime as plain numbers, so the app only turns them into samples.
public enum ChimeRenderer {
    public static func render(sampleRate: Int) -> [Float] {
        SoundRenderer.render(MotifTable.celebration, sampleRate: sampleRate)
    }
}
