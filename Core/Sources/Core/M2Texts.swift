extension TextTable {
    /// Child text of the Math M2 level; prompts are 1 to 3 words, each with its keyword.
    static let m2Texts: [String: TextEntry] = [
        "trail.level.math-m2-ten.title": TextEntry("Composer dix", "Compose ten"),
        "m2.prompt.fillTenFrame": TextEntry("Remplis la boîte", "Fill the frame"),
        "m2.prompt.fillTenFrame.keyword": TextEntry("Remplis", "Fill"),
        "m2.prompt.pickBaskets": TextEntry("Choisis deux paniers", "Pick two baskets"),
        "m2.prompt.pickBaskets.keyword": TextEntry("Choisis", "Pick"),
        "m2.prompt.missingPart": TextEntry("Trouve la partie", "Find the part"),
        "m2.prompt.missingPart.keyword": TextEntry("partie", "part"),
        "m2.speech.fillTenFrame": TextEntry("Regarde combien de cases vides restent dans la boîte à dix.",
                                           "Look at how many empty spaces are left in the ten frame."),
        "m2.speech.pickBaskets": TextEntry("Compte les objets des deux paniers ensemble.",
                                          "Count the objects in both baskets together."),
        "m2.speech.missingPart": TextEntry("Cherche la partie qui manque dans le calcul.",
                                          "Look for the missing part in the number sentence."),
        "m2.hint": TextEntry("Compte les cases vides, puis essaie encore.",
                             "Count the empty spaces, then try again."),
        "m2.help.whole": TextEntry("Regarde le tout : les deux parties réunies.",
                                   "Look at the whole: both parts together."),
        "m2.help.spaces": TextEntry("Les cases pleines et les cases vides sont montrées.",
                                    "The filled spaces and the empty spaces are shown."),
        "m2.help.move": TextEntry("Une partie glisse dans une boîte déjà remplie.",
                                  "One part moves into a box that is already worked.")
    ]
}
