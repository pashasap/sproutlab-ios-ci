import Foundation

/// The 17 behaviours a resident can perform; the raw value is the case name.
public enum Behaviour: String, CaseIterable, Sendable {
    case breathe, blink, sway, wander, hop, crawl, flutter, hover, glide
    case perch, curl, hideInShell, glowPulse, visit, dig, peek, sleep
}

/// One named parameter with its declared bound.
public struct BehaviourParameter: Equatable, Sendable {
    public let name: String
    public let value: Double
    public let lower: Double
    public let upper: Double
}

public struct BehaviourSpec: Equatable, Sendable {
    public let behaviour: Behaviour
    public let parameters: [BehaviourParameter]

    public func value(_ name: String) -> Double? {
        parameters.first { $0.name == name }?.value
    }

    /// Seconds of one cycle: the period when declared, else the inverse of the frequency.
    public var cycleSeconds: Double? {
        if let period = value("period") { return period }
        return value("frequency").flatMap { $0 > 0 ? 1 / $0 : nil }
    }

    public func bounds(_ name: String) -> ClosedRange<Double>? {
        parameters.first { $0.name == name }.map { $0.lower...$0.upper }
    }
}

public struct ResidentBehaviours: Equatable, Sendable {
    public let idle: [BehaviourSpec]
    public let tap: [BehaviourSpec]
}

/// Behaviours as data: 2 or 3 idle behaviours and 1 tap reaction per resident.
public enum BehaviourTable {
    public static let amplitudeBounds = 0.0...12.0
    public static let frequencyBounds = 0.05...1.2
    public static let periodBounds = 3.0...12.0
    public static let depthBounds = 0.0...0.5

    static func motion(_ behaviour: Behaviour, _ amplitude: Double, _ frequency: Double) -> BehaviourSpec {
        BehaviourSpec(behaviour: behaviour, parameters: [
            BehaviourParameter(name: "amplitude", value: amplitude,
                               lower: amplitudeBounds.lowerBound, upper: amplitudeBounds.upperBound),
            BehaviourParameter(name: "frequency", value: frequency,
                               lower: frequencyBounds.lowerBound, upper: frequencyBounds.upperBound),
        ])
    }

    static func glow(period: Double, depth: Double) -> BehaviourSpec {
        BehaviourSpec(behaviour: .glowPulse, parameters: [
            BehaviourParameter(name: "period", value: period,
                               lower: periodBounds.lowerBound, upper: periodBounds.upperBound),
            BehaviourParameter(name: "depth", value: depth,
                               lower: depthBounds.lowerBound, upper: depthBounds.upperBound),
        ])
    }

    private static func entry(_ idle: [BehaviourSpec], tap: BehaviourSpec) -> ResidentBehaviours {
        ResidentBehaviours(idle: idle, tap: [tap])
    }

    private static let table: [String: ResidentBehaviours] = [
        "sunflower": entry([motion(.sway, 6, 0.2), motion(.breathe, 4, 0.25)], tap: motion(.sway, 8, 0.5)),
        "earthworm": entry([motion(.crawl, 8, 0.12), motion(.dig, 4, 0.3)], tap: motion(.curl, 6, 0.4)),
        "ant": entry([motion(.wander, 12, 0.08), motion(.dig, 3, 0.4)], tap: motion(.peek, 5, 0.5)),
        "fern": entry([motion(.sway, 5, 0.15), motion(.breathe, 3, 0.2)], tap: motion(.sway, 7, 0.45)),
        "ladybug": entry([motion(.crawl, 8, 0.1), motion(.flutter, 3, 0.8), motion(.perch, 3, 0.2)],
                         tap: motion(.flutter, 5, 1.0)),
        "tree-frog": entry([motion(.breathe, 4, 0.3), motion(.blink, 3, 0.2), motion(.hop, 5, 0.35)],
                           tap: motion(.hop, 7, 0.6)),
        "glowing-mushroom": entry([glow(period: 5, depth: 0.3), motion(.breathe, 3, 0.2)],
                                  tap: glow(period: 4, depth: 0.4)),
        "axolotl": entry([motion(.sway, 6, 0.2), motion(.blink, 3, 0.15), motion(.glide, 8, 0.1)],
                         tap: motion(.glide, 9, 0.3)),
        "butterfly": entry([motion(.flutter, 4, 1.0), motion(.glide, 10, 0.07), motion(.perch, 3, 0.2)],
                           tap: motion(.flutter, 6, 1.1)),
        "honeybee": entry([motion(.hover, 4, 0.7), motion(.visit, 8, 0.1), motion(.wander, 10, 0.06)],
                          tap: motion(.hover, 6, 0.9)),
        "snail": entry([motion(.crawl, 6, 0.06), motion(.breathe, 3, 0.2), motion(.hideInShell, 4, 0.1)],
                       tap: motion(.hideInShell, 6, 0.3)),
        "poppy": entry([motion(.sway, 6, 0.18), motion(.breathe, 3, 0.22)], tap: motion(.sway, 8, 0.5)),
        "dandelion": entry([motion(.sway, 7, 0.16), motion(.breathe, 3, 0.2)], tap: motion(.flutter, 6, 0.8)),
        "robin": entry([motion(.hop, 5, 0.3), motion(.perch, 3, 0.2), motion(.blink, 3, 0.15)],
                       tap: motion(.peek, 6, 0.5)),
        "cricket": entry([motion(.sleep, 3, 0.15), motion(.blink, 3, 0.2), motion(.hop, 4, 0.3)],
                         tap: motion(.hop, 6, 0.7)),
    ]

    /// nil for unknown ids.
    public static func entry(for resident: String) -> ResidentBehaviours? {
        table[resident]
    }
}
