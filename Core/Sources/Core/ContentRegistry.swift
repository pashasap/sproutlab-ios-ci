public struct ContentTextTable: Sendable {
    public var id: String
    public var entries: [String: TextEntry]

    public init(id: String, entries: [String: TextEntry]) {
        self.id = id
        self.entries = entries
    }
}

/// Register tables here once: runtime text lookup and lint consume the same list.
public struct ContentRegistry: Sendable {
    public var levels: [LevelDefinition]
    public var tables: [ContentTextTable]
    public var symbolNames: [String]
    public var colourTokens: [String]
    public var helpSteps: [String: ContentHelpStep] = [:]
    public var recipes: [Recipe] = Recipe.table

    public init(levels: [LevelDefinition], tables: [ContentTextTable],
                symbolNames: [String], colourTokens: [String]) {
        self.levels = levels
        self.tables = tables
        self.symbolNames = symbolNames
        self.colourTokens = colourTokens
    }

    public static var shipped: ContentRegistry {
        ContentRegistry(levels: LevelCatalog.standard.levels, tables: textTables,
                        symbolNames: ChromeCatalog.allSymbolNames, colourTokens: knownColourTokens.sorted())
    }

    // Committed V5 identity baseline. Do not generate this from the current catalog.
    public static let v5LevelIDs = ["math-bonds-10"]
    public static let knownColourTokens: Set<String> = Set([
        "colour.math", "colour.counting", "colour.bond",
        "colour.green", "colour.locked", "colour.accent", "colour.suggested", "colour.review",
        "colour.robot", "colour.dot", "colour.mark", "colour.markHalo", "colour.ink"
    ]).union(ColourTokens.allTokens)

    public static let textTables: [ContentTextTable] = [
        ContentTextTable(id: "welcome-trail", entries: TextTable.welcomeTrailTexts),
        ContentTextTable(id: "round", entries: TextTable.roundTexts),
        ContentTextTable(id: "summary", entries: TextTable.summaryTexts),
        ContentTextTable(id: "settings", entries: TextTable.settingsTexts),
        ContentTextTable(id: "notices", entries: TextTable.noticeTexts),
        ContentTextTable(id: "accessibility", entries: TextTable.accessibilityTexts),
        ContentTextTable(id: "app-shell", entries: TextTable.appShellTexts),
        ContentTextTable(id: "icons", entries: TextTable.iconTexts),
        ContentTextTable(id: "icon-labels", entries: TextTable.iconLabelTexts),
        ContentTextTable(id: "activities", entries: TextTable.activityTexts),
        ContentTextTable(id: "math-m1", entries: TextTable.m1Texts),
        ContentTextTable(id: "math-m2", entries: TextTable.m2Texts),
        ContentTextTable(id: "math-m3", entries: TextTable.m3Texts),
        ContentTextTable(id: "math-m4", entries: TextTable.m4Texts),
        ContentTextTable(id: "chrome", entries: TextTable.chromeTexts),
        ContentTextTable(id: "add-sub", entries: TextTable.addSubTexts),
        ContentTextTable(id: "patterns", entries: TextTable.patternsTexts),
        ContentTextTable(id: "trail-states", entries: TextTable.trailStateTexts),
        ContentTextTable(id: "recipe-names", entries: TextTable.recipeNameTexts),
        ContentTextTable(id: "gallery", entries: TextTable.galleryTexts),
        ContentTextTable(id: "terrarium", entries: TextTable.terrariumTexts),
        ContentTextTable(id: "journal", entries: TextTable.journalTexts),
        ContentTextTable(id: "kit", entries: TextTable.kitTexts.merging(TextTable.laneTexts) { first, _ in first }),
        ContentTextTable(id: "reading", entries: TextTable.readingTexts.merging(TextTable.readingR1Texts) { first, _ in first }),
        ContentTextTable(id: "reading-r2", entries: TextTable.readingR2Texts),
        ContentTextTable(id: "reading-r3", entries: TextTable.readingR3Texts),
        ContentTextTable(id: "reading-r6", entries: TextTable.readingFR6Texts),
        ContentTextTable(id: "reading-en-r6", entries: TextTable.readingEN6Texts),
        ContentTextTable(id: "reading-recipes", entries: TextTable.readingRecipeTexts),
        ContentTextTable(id: "reading-en", entries: TextTable.readingENTexts),
        ContentTextTable(id: "robot", entries: TextTable.robotTexts.merging(TextTable.robotRecipeTexts) { first, _ in first }),
        ContentTextTable(id: "music", entries: TextTable.musicTexts.merging(TextTable.musicA4Texts) { first, _ in first })
    ]
}

/// All answer-bearing help state is explicit, so lint can also check injected steps.
public struct ContentHelpState: Sendable {
    public var stimulus: QuestionStimulus
    public var choices: [Int]
    public var correctIndex: Int
    public var promptKey: String

    public init(item: Item) {
        stimulus = item.stimulus
        choices = item.choices
        correctIndex = item.correctIndex
        promptKey = item.promptKey
    }

    public var correctOption: Int? {
        choices.indices.contains(correctIndex) ? choices[correctIndex] : nil
    }
}

public struct ContentHelpStep: Sendable {
    private let transform: @Sendable (ContentHelpState, Language) -> ContentHelpState

    public init(apply: @escaping @Sendable (ContentHelpState, Language) -> ContentHelpState) {
        transform = apply
    }

    public func applying(to state: ContentHelpState, language: Language) -> ContentHelpState {
        transform(state, language)
    }

    /// Shipped help highlights and dims choices, without changing the question.
    public static let highlight = ContentHelpStep { state, _ in state }
}
