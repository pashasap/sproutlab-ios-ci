extension TextTable {
    /// Child text of the Math M3 level; prompts are 1 to 3 words, each with its keyword.
    static let m3Texts: [String: TextEntry] = [
        "trail.level.math-m3-bridge-ten.title": TextEntry("Passer par dix", "Bridge through ten"),
        "m3.prompt.count": TextEntry("Compte les points", "Count the dots"),
        "m3.prompt.count.keyword": TextEntry("points", "dots"),
        "m3.prompt.take": TextEntry("Enlève puis compte", "Remove then count"),
        "m3.prompt.take.keyword": TextEntry("Enlève", "Remove"),
        "m3.speech.count": TextEntry("Regarde les deux boîtes à dix et additionne.",
                                     "Look at both ten-frames and add them."),
        "m3.speech.take": TextEntry("Regarde les points, puis enlève-en une partie.",
                                    "Look at the dots, then take some away."),
        "m3.hint": TextEntry("Compte les cases pleines, puis essaie encore.",
                             "Count the filled spaces, then try again."),
        "m3.help.frames": TextEntry("Regarde les deux boîtes à dix.",
                                    "Look at both ten-frames."),
        "m3.help.ten": TextEntry("Sépare ce qu'il faut pour arriver à dix.",
                                 "Split off the part that reaches ten."),
        "m3.help.first": TextEntry("Fais le premier pas, puis garde le reste.",
                                   "Do the first step, then keep the rest."),
        "m3.view.remove": TextEntry("Enlève %1", "Take away %1"),
        "m3.view.separate": TextEntry("Sépare %1", "Split off %1"),
        "m3.view.rest": TextEntry("Reste %1", "Left %1")
    ]
}
