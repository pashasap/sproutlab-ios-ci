public enum KitRevealPhase: Sendable, Equatable {
    case idle, answering, submitted
}

public enum KitRevealResult: Sendable, Equatable {
    case denied, shown
}

/// A picture that stays hidden until an answer has been submitted.
public struct KitPictureReveal: KitComponent {
    public let answers: [String]
    public private(set) var phase: KitRevealPhase = .idle
    public private(set) var submittedAnswer: String?
    public private(set) var announcements: [KitAnnouncement] = []

    public init(answers: [String]) {
        self.answers = answers
    }

    public var pictureVisible: Bool { phase == .submitted }

    public mutating func beginAnswering() {
        guard phase == .idle else { return }
        phase = .answering
        announcements.append(KitAnnouncement(key: "kit.say.answering"))
    }

    public mutating func submit(_ answer: String) {
        guard phase != .submitted else { return }
        submittedAnswer = answer
        phase = .submitted
        announcements.append(KitAnnouncement(key: "kit.say.revealed", subject: answer))
    }

    @discardableResult
    public mutating func reveal() -> KitRevealResult {
        pictureVisible ? .shown : .denied
    }

    public mutating func reset() {
        guard phase != .idle else { return }
        phase = .idle
        submittedAnswer = nil
        announcements.append(KitAnnouncement(key: "kit.say.reset"))
    }

    public mutating func apply(_ command: KitCommand) {
        switch command {
        case .beginAnswering: beginAnswering()
        case .submit(let answer): submit(answer)
        case .reveal: reveal()
        case .reset: reset()
        default: break
        }
    }

    public var accessibilityActions: [KitAccessibilityAction] {
        switch phase {
        case .idle:
            return [KitAccessibilityAction(labelKey: "kit.action.begin", command: .beginAnswering)]
        case .answering:
            return answers.map { KitAccessibilityAction(labelKey: "kit.action.submit", command: .submit($0), subject: $0) }
                + [KitAccessibilityAction(labelKey: "kit.action.reveal", command: .reveal)]
        case .submitted:
            return [KitAccessibilityAction(labelKey: "kit.action.reveal", command: .reveal),
                    KitAccessibilityAction(labelKey: "kit.action.reset", command: .reset)]
        }
    }

    public var tapTargets: [KitTapTarget] {
        switch phase {
        case .idle:
            return [KitTapTarget(identifier: KitIdentifier.make("begin"), command: .beginAnswering)]
        case .answering:
            return answers.enumerated().map { index, answer in
                KitTapTarget(identifier: KitIdentifier.make("answer", index), command: .submit(answer), subject: answer)
            }
        case .submitted:
            return [KitTapTarget(identifier: KitIdentifier.make("reset"), command: .reset)]
        }
    }
}
