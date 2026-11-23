extension TextTable {
    /// Texts of the patterns level: title, prompts, keywords, help, hints and text equivalents.
    static let patternsTexts: [String: TextEntry] = [
        "trail.level.math-patterns-20.title": TextEntry("Suites et tailles", "Patterns, sizes"),
        "round.prompt.pattern": TextEntry("Quel nombre manque ?", "Which is missing?"),
        "round.prompt.pattern.keyword": TextEntry("manque", "missing"),
        "round.prompt.larger": TextEntry("La plus grande ?", "Which is larger?"),
        "round.prompt.larger.keyword": TextEntry("grande", "larger"),
        "round.prompt.smaller": TextEntry("La plus petite ?", "Which is smaller?"),
        "round.prompt.smaller.keyword": TextEntry("petite", "smaller"),
        "round.help.step": TextEntry("Regarde de combien la suite avance.", "See how far each step goes."),
        "round.help.compare": TextEntry("Compare les deux groupes de points.", "Compare the two groups of dots."),
        "round.hint.pattern": TextEntry("Regarde le pas entre les nombres, puis essaie encore.",
                                        "Look at the step between the numbers, then try again."),
        "round.hint.compare": TextEntry("Compare les deux groupes, puis essaie encore.",
                                        "Compare the two groups, then try again."),
        "equiv.empty-place": TextEntry("une place vide", "one empty place")
    ]
}
