import Foundation

/// One finished round in the star history. It never changes the award.
public struct RoundEntry: Equatable, Codable, Sendable {
    public var levelId: String
    public var date: Date
    public var firstTryCount: Int
    public var helpUsed: Bool

    public init(levelId: String, date: Date, firstTryCount: Int, helpUsed: Bool) {
        self.levelId = levelId
        self.date = date
        self.firstTryCount = firstTryCount
        self.helpUsed = helpUsed
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        levelId = try c.decodeIfPresent(String.self, forKey: .levelId) ?? ""
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date(timeIntervalSince1970: 0)
        firstTryCount = try c.decodeIfPresent(Int.self, forKey: .firstTryCount) ?? 0
        helpUsed = try c.decodeIfPresent(Bool.self, forKey: .helpUsed) ?? false
    }
}

public struct SettingsSection: Equatable, Codable, Sendable {
    public var language: Language = .fr
    public var music: Bool = false

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        language = try c.decodeIfPresent(Language.self, forKey: .language) ?? .fr
        music = try c.decodeIfPresent(Bool.self, forKey: .music) ?? false
    }
}

public struct StarsSection: Equatable, Codable, Sendable {
    public static let historyCap = 50
    public var total: Int = 0
    public var history: [RoundEntry] = []

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        total = try c.decodeIfPresent(Int.self, forKey: .total) ?? 0
        history = try c.decodeIfPresent([RoundEntry].self, forKey: .history) ?? []
    }
}

public struct LevelProgress: Equatable, Codable, Sendable {
    public var completions: Int = 0
    public var independentCompletions: Int = 0
    public var visits: Int = 0
    public var unfamiliarSeen: Int = 0
    public var lastSession: Int = 0
    public var reviewStage: Int = 0
    /// Unique, ascending configurations of items seen in committed rounds of this level.
    public var configurationsSeen: [Int] = []

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        completions = try c.decodeIfPresent(Int.self, forKey: .completions) ?? 0
        independentCompletions = try c.decodeIfPresent(Int.self, forKey: .independentCompletions) ?? 0
        visits = try c.decodeIfPresent(Int.self, forKey: .visits) ?? 0
        unfamiliarSeen = try c.decodeIfPresent(Int.self, forKey: .unfamiliarSeen) ?? 0
        lastSession = try c.decodeIfPresent(Int.self, forKey: .lastSession) ?? 0
        reviewStage = try c.decodeIfPresent(Int.self, forKey: .reviewStage) ?? 0
        configurationsSeen = try c.decodeIfPresent([Int].self, forKey: .configurationsSeen) ?? []
    }
}

/// A collectible welcomed once, with the date it was welcomed.
public struct WelcomeEntry: Equatable, Codable, Sendable {
    public var id: String
    public var date: Date

    public init(id: String, date: Date) {
        self.id = id
        self.date = date
    }

    private enum CodingKeys: String, CodingKey { case id, date }

    /// The date is stored as plain seconds since 1970, so a saved file reads the same on every platform.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        date = Date(timeIntervalSince1970: try c.decode(Double.self, forKey: .date))
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date.timeIntervalSince1970, forKey: .date)
    }
}

public struct CollectionSection: Equatable, Codable, Sendable {
    public var items: [String] = []
    public var welcomed: [WelcomeEntry] = []
    public var isEmpty: Bool { items.isEmpty && welcomed.isEmpty }

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = try c.decodeIfPresent([String].self, forKey: .items) ?? []
        welcomed = try c.decodeIfPresent([WelcomeEntry].self, forKey: .welcomed) ?? []
    }
}

/// A nature-journal stamp a resident can earn.
public enum Stamp: String, CaseIterable, Codable, Sendable {
    case seenAtNight, heard, counted, fed
}

/// The stamps one resident has earned (schema 4).
public struct ResidentStamps: Equatable, Codable, Sendable {
    public var seenAtNight = false
    public var heard = false
    public var counted = false
    public var fed = false

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        seenAtNight = try c.decodeIfPresent(Bool.self, forKey: .seenAtNight) ?? false
        heard = try c.decodeIfPresent(Bool.self, forKey: .heard) ?? false
        counted = try c.decodeIfPresent(Bool.self, forKey: .counted) ?? false
        fed = try c.decodeIfPresent(Bool.self, forKey: .fed) ?? false
    }

    public func has(_ stamp: Stamp) -> Bool {
        switch stamp {
        case .seenAtNight: return seenAtNight
        case .heard: return heard
        case .counted: return counted
        case .fed: return fed
        }
    }

    mutating func set(_ stamp: Stamp) {
        switch stamp {
        case .seenAtNight: seenAtNight = true
        case .heard: heard = true
        case .counted: counted = true
        case .fed: fed = true
        }
    }
}

public struct CreationsSection: Equatable, Codable, Sendable {
    public var items: [String] = []
    /// Child-made rhythm patterns, kept as symbolic events only.
    public var musicPatterns: [MusicA4Pattern] = []
    public var isEmpty: Bool { items.isEmpty && musicPatterns.isEmpty }

    private enum CodingKeys: String, CodingKey { case items, musicPatterns }

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = try c.decodeIfPresent([String].self, forKey: .items) ?? []
        musicPatterns = try c.decodeIfPresent([MusicA4Pattern].self, forKey: .musicPatterns) ?? []
    }

    /// Older files stay byte-identical: the patterns key is written only when there are patterns.
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(items, forKey: .items)
        if !musicPatterns.isEmpty { try c.encode(musicPatterns, forKey: .musicPatterns) }
    }

    public mutating func save(_ pattern: MusicA4Pattern) {
        musicPatterns.append(pattern)
    }
}
