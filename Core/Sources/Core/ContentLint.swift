public struct ContentFinding: Sendable, Equatable, Hashable {
    public let kind: String
    public let subject: String

    public init(kind: String, subject: String) {
        self.kind = kind
        self.subject = subject
    }
}

public enum ContentLint {
    public static func run(registry: ContentRegistry) -> [ContentFinding] {
        var findings = tableFindings(registry)
        findings += identityFindings(registry.levels)
        findings += reachabilityFindings(registry.levels)
        findings += RecipeLint.run(registry.recipes)
        for symbol in registry.symbolNames where !ChromeCatalog.allSymbolNames.contains(symbol) {
            findings.append(ContentFinding(kind: "unknown-symbol", subject: symbol))
        }
        for token in registry.colourTokens where !ContentRegistry.knownColourTokens.contains(token) {
            findings.append(ContentFinding(kind: "unknown-colour", subject: token))
        }
        findings += readingENFindings(ReadingENBank.allItems)
        findings += frenchTextFindings(FrenchTextBank.items)
        findings += englishTextFindings(EnglishTextBank.items)
        let texts = mergedTexts(registry.tables)
        for level in registry.levels {
            findings += levelFindings(level, registry: registry, texts: texts)
        }
        return Set(findings).sorted { ($0.kind, $0.subject) < ($1.kind, $1.subject) }
    }

    static func identityFindings(_ levels: [LevelDefinition]) -> [ContentFinding] {
        var seen = Set<String>()
        var findings: [ContentFinding] = []
        for level in levels where !seen.insert(level.levelId).inserted {
            findings.append(ContentFinding(kind: "duplicate-level-id", subject: level.levelId))
        }
        for id in ContentRegistry.v5LevelIDs where !seen.contains(id) {
            findings.append(ContentFinding(kind: "unstable-v5-id", subject: id))
        }
        return findings
    }

    public static func reachableLevelIDs(_ levels: [LevelDefinition]) -> [String] {
        var record = ProgressRecord.fresh()
        var reached: [String] = []
        while let next = levels.first(where: {
            !reached.contains($0.levelId) && $0.prerequisites.allSatisfy(record.completedLevels.contains)
        }) {
            reached.append(next.levelId)
            record = record.completing(levelId: next.levelId, stars: ProgressRecord.starsPerRound)
        }
        return reached
    }

    static func reachabilityFindings(_ levels: [LevelDefinition]) -> [ContentFinding] {
        let reached = Set(reachableLevelIDs(levels))
        return levels.filter { !reached.contains($0.levelId) }.map {
            ContentFinding(kind: "unreachable-level", subject: $0.levelId)
        }
    }

    /// Exhaustive registered domain plus live-round variants (including option permutations).
    static func items(_ level: LevelDefinition) -> [Item] {
        var result = level.configurations?() ?? []
        for seed in UInt64(0)..<4096 { result += level.generator(seed) }
        return result
    }

    static func levelFindings(_ level: LevelDefinition, registry: ContentRegistry,
                              texts: [String: TextEntry]) -> [ContentFinding] {
        let generated = items(level)
        let configurations = Set(generated.map { "\($0.kind.rawValue):\($0.configuration)" })
        var findings: [ContentFinding] = []
        if configurations.count < 24 && level.strand != "readingFR" && level.strand != "readingEN" {
            findings.append(ContentFinding(kind: "too-few-configurations", subject: level.levelId))
        }
        for key in [level.titleKey, level.iconKey] + level.helpSteps where texts[key] == nil {
            findings.append(ContentFinding(kind: "missing-text-key", subject: key))
        }
        findings += colourFindings(level.colourName)
        for item in generated {
            findings += item.readingId == nil ? itemFindings(item, level: level, registry: registry)
                                              : readingFindings(item, level: level)
            for key in [item.promptKey, item.iconKey, item.identity.accessibilityNameKey, item.hintKey]
                where texts[key] == nil {
                findings.append(ContentFinding(kind: "missing-text-key", subject: key))
            }
            findings += colourFindings(item.colourName)
        }
        return findings
    }

    static func colourFindings(_ token: String) -> [ContentFinding] {
        ContentRegistry.knownColourTokens.contains(token) ? [] : [ContentFinding(kind: "unknown-colour", subject: token)]
    }
}
