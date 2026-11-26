extension TextTable {
    /// Child text of the Math M1 level; prompts are 1 to 3 words, each with its keyword.
    static let m1Texts: [String: TextEntry] = [
        "trail.level.math-m1-count.title": TextEntry("Compter", "Counting"),
        "m1.prompt.tapCount": TextEntry("Compte les objets", "Count the objects"),
        "m1.prompt.tapCount.keyword": TextEntry("Compte", "Count"),
        "m1.prompt.fillTray": TextEntry("Remplis le plateau", "Fill the tray"),
        "m1.prompt.fillTray.keyword": TextEntry("Remplis", "Fill"),
        "m1.prompt.matchGroups": TextEntry("Trouve autant", "Find the same"),
        "m1.prompt.matchGroups.keyword": TextEntry("autant", "same"),
        "m1.speech.tapCount": TextEntry("Touche chaque objet une seule fois, puis touche le nombre.",
                                        "Touch each object once, then touch the number."),
        "m1.speech.fillTray": TextEntry("Combien de places vides y a-t-il dans le plateau ?",
                                        "How many empty places are in the tray?"),
        "m1.speech.matchGroups": TextEntry("Touche le nombre d'objets qui est le même, même rangé autrement.",
                                           "Touch the number of objects that is the same, even when arranged differently."),
        "m1.hint": TextEntry("Touche chaque objet une seule fois, puis essaie encore.",
                             "Touch each object once, then try again."),
        "m1.help.mark": TextEntry("Les objets comptés sont marqués.", "Counted objects get a mark."),
        "m1.help.row": TextEntry("Les objets se rangent en une file.", "The objects line up in a row."),
        "m1.help.demo": TextEntry("Compte tous les objets sauf le dernier.", "Count every object except the last one.")
    ]
}
