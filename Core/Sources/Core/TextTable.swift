public enum Language: String, Sendable, Codable, CaseIterable {
    case fr
    case en

    public static let `default`: Language = .fr
}

public struct TextEntry: Sendable {
    public let fr: String
    public let en: String

    public init(_ fr: String, _ en: String) {
        self.fr = fr
        self.en = en
    }
}

public enum TextTable {
    static let entries: [String: TextEntry] = {
        var all: [String: TextEntry] = [:]
        for table in ContentRegistry.textTables {
            all.merge(table.entries) { first, _ in first }
        }
        return all
    }()

    /// Primary lookup keys; icon accessibility labels remain companion keys, not symbols.
    /// ContentRegistry still registers and lints every companion label entry.
    public static var allKeys: [String] {
        entries.keys.filter { !($0.hasPrefix("icon.") && $0.hasSuffix(".label")) }.sorted()
    }

    public static func string(_ key: String, _ language: Language) -> String {
        guard let entry = entries[key] ?? iconLabel(key) else { return key }
        switch language {
        case .fr: return entry.fr
        case .en: return entry.en
        }
    }
}
