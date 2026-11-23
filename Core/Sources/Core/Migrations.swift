import Foundation

public enum MigrationError: Error, Equatable, Sendable {
    case corrupt
    case unsupportedVersion(Int)
}

/// Chain of schema steps. Each step turns the JSON object of version N into version N + 1.
public enum Migrations {
    typealias Step = @Sendable ([String: Any]) -> [String: Any]

    static let steps: [Int: Step] = [1: v1ToV2, 2: v2ToV3, 3: v3ToV4]

    /// V4 to V5 keeps every field and adds the empty, separate readingEN section.
    private static let v4ToV5: Step = { old in
        var out = old
        if out["readingEN"] == nil { out["readingEN"] = [String: Any]() }
        return out
    }

    /// V3 to V4 keeps every field and adds the empty journal stamps.
    private static let v3ToV4: Step = { old in
        var out = old
        if out["stamps"] == nil { out["stamps"] = [String: Any]() }
        return out
    }

    /// V2 to V3 keeps every field and adds the empty welcomed list to the collection section.
    private static let v2ToV3: Step = { old in
        var out = old
        var collection = old["collection"] as? [String: Any] ?? [:]
        if collection["welcomed"] == nil { collection["welcomed"] = [Any]() }
        out["collection"] = collection
        return out
    }

    public static func migrate(data: Data) throws -> ProgressRecord {
        guard var object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              var version = object["schemaVersion"] as? Int, version >= 1 else {
            throw MigrationError.corrupt
        }
        guard version <= ProgressRecord.currentVersion else {
            throw MigrationError.unsupportedVersion(version)
        }
        while version < ProgressRecord.currentVersion {
            guard let step = steps[version] else { throw MigrationError.corrupt }
            object = step(object)
            version += 1
            object["schemaVersion"] = version
        }
        guard let upgraded = try? JSONSerialization.data(withJSONObject: object),
              let record = try? JSONDecoder().decode(ProgressRecord.self, from: upgraded) else {
            throw MigrationError.corrupt
        }
        return record
    }

    /// V1 kept stars, completed levels (as completions >= 1), language and music.
    private static let v1ToV2: Step = { old in
        var settings: [String: Any] = [:]
        if let language = old["language"] { settings["language"] = language }
        if let music = old["musicOn"] { settings["music"] = music }
        var levels: [String: Any] = [:]
        for id in old["completedLevels"] as? [String] ?? [] { levels[id] = ["completions": 1] }
        var out: [String: Any] = ["settings": settings, "levels": levels]
        if let total = old["totalStars"] { out["stars"] = ["total": total] }
        return out
    }
}
