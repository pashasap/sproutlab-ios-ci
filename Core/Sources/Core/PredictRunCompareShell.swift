import Foundation

public enum PredictRunCompareError: Error, Equatable {
    case predictionRequired
}

/// Predict first, then run, then compare planned (dotted) with actual (solid). Nothing is scored.
public struct PredictRunCompareShell<Event: Hashable & Sendable & RawRepresentable<String>>: Sendable {
    public struct Comparison: Sendable {
        public let planned: [Event]
        public let actual: [Event]
        public let outcomeLabel: String
    }

    public private(set) var strip: GenericProgramStrip<Event>
    public private(set) var prediction: [Event]?
    private var actual: [Event] = []
    private let authoredOutcome: String

    public init(strip: GenericProgramStrip<Event>, authoredOutcome: String) {
        self.strip = strip
        self.authoredOutcome = authoredOutcome
    }

    /// The ghost marker shows the recorded prediction before and during the run.
    public var ghost: [Event]? { prediction }
    public var playhead: Int { strip.playhead }

    public mutating func predict(_ events: [Event]) { prediction = events }
    public mutating func add(_ event: Event) { strip.add(event) }
    public mutating func undo() { strip.undo() }

    public mutating func step() throws -> Event? {
        guard prediction != nil else { throw PredictRunCompareError.predictionRequired }
        guard let event = strip.step() else { return nil }
        actual.append(event)
        return event
    }

    public mutating func play() throws -> [Event] {
        guard prediction != nil else { throw PredictRunCompareError.predictionRequired }
        let played = strip.play()
        actual.append(contentsOf: played)
        return played
    }

    public mutating func rewind() {
        strip.rewind()
        actual = []
    }

    public mutating func reset() {
        strip.reset()
        actual = []
        prediction = nil
    }

    public func compare() -> Comparison {
        Comparison(planned: prediction ?? [], actual: actual, outcomeLabel: authoredOutcome)
    }
}
