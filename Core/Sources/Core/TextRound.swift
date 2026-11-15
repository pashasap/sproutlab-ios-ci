extension TextTable {
    static let roundTexts: [String: TextEntry] = [
        "round.prompt.count": TextEntry("Combien de points vois-tu ?", "How many dots do you see?"),
        "round.prompt.bond": TextEntry("Combien manque-t-il pour faire 10 ?", "How many more to make 10?"),
        "round.prompt.count.keyword": TextEntry("points", "dots"),
        "round.prompt.bond.keyword": TextEntry("manque", "more"),
        "round.progress": TextEntry("Question", "Question"),
        "round.encourage": TextEntry("Regarde bien les groupes de points.",
                                     "Look closely at the groups of dots."),
        "round.look-at-dots": TextEntry("Compte les points, puis essaie encore.",
                                        "Count the dots, then try again."),
        "round.count-empty": TextEntry("Compte les places vides.", "Count the empty places."),
        "round.correct": TextEntry("Bravo !", "Well done!"),
        "round.help.groups": TextEntry("Regarde les groupes de points.", "Look at the groups of dots."),
        "round.help.count": TextEntry("Compte les points un par un.", "Count the dots one by one."),
        "speak.button": TextEntry("Appuie pour écouter", "Tap to Hear")
    ]

    static let summaryTexts: [String: TextEntry] = [
        "summary.title": TextEntry("Bravo, tu as réussi !", "Great job, you did it!"),
        "summary.stars": TextEntry("Tu gagnes 3 étoiles", "You earn 3 stars"),
        "summary.back": TextEntry("Retour au sentier", "Back to the trail")
    ]
}
