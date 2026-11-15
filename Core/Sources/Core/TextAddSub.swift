extension TextTable {
    /// Texts of the add-and-subtract level: title, prompts, keywords, help, hints and text equivalents.
    static let addSubTexts: [String: TextEntry] = [
        "trail.level.math-add-sub-20.title": TextEntry("Additions et soustractions jusqu'à 20",
                                                       "Add and take away up to 20"),
        "round.prompt.add": TextEntry("Combien de points en tout ?", "How many dots in all?"),
        "round.prompt.add.keyword": TextEntry("en tout", "in all"),
        "round.prompt.subtract": TextEntry("Combien de points restent-ils ?", "How many dots are left?"),
        "round.prompt.subtract.keyword": TextEntry("restent", "left"),
        "round.help.join": TextEntry("Regarde les deux groupes de points.", "Look at the two groups of dots."),
        "round.help.crossed": TextEntry("Les points barrés ne comptent pas.", "Crossed-out dots do not count."),
        "round.hint.add": TextEntry("Compte les deux groupes ensemble, puis essaie encore.",
                                    "Count both groups together, then try again."),
        "round.hint.subtract": TextEntry("Ne compte pas les points barrés, puis essaie encore.",
                                         "Skip the crossed-out dots, then try again."),
        "equiv.colon": TextEntry(" : ", ": "),
        "equiv.groups": TextEntry("deux groupes de points", "two groups of dots"),
        "equiv.crossed-out": TextEntry("barrés", "crossed out"),
        "equiv.and": TextEntry(" et ", " and ")
    ]
}
