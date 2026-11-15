/// One rung of the three-step help ladder: text and symbols only, never a change to the question.
public struct HelpStepPresentation: Sendable, Equatable {
    public let kind: String
    public let text: String
    public let symbolNames: [String]
    public let colourTokens: [String]
}

public enum HelpLadder {
    public static let kinds = ["cue", "partialWorked", "oneMoveDemonstration"]

    /// Cue (the hint), partial worked example, one-move demonstration; texts are in `language`.
    static func steps(item: Item, levelId: String, language: Language) -> [HelpStepPresentation] {
        let own = LevelCatalog.standard.levels.first { $0.levelId == levelId }?.helpSteps ?? []
        let keys = own.count == kinds.count
            ? own : [item.hintKey, own.first ?? item.hintKey, own.dropFirst().first ?? item.hintKey]
        return kinds.indices.map { index in
            HelpStepPresentation(kind: kinds[index], text: TextTable.string(keys[index], language),
                                 symbolNames: [ChromeCatalog.helpSymbolNames[index]],
                                 colourTokens: ["colour.accent"])
        }
    }
}
