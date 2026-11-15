extension TextTable {
    /// Titles, instructions and help steps of the French reading track.
    static let readingTexts: [String: TextEntry] = [
        "trail.level.reading-fr-r1.title": TextEntry("Lecture : les sons et les voyelles", "Reading: sounds and vowels"),
        "trail.level.reading-fr-r2.title": TextEntry("Lecture : syllabes et petits mots", "Reading: syllables and short words"),
        "trail.level.reading-fr-r3.title": TextEntry("Lecture : ch et ou", "Reading: ch and ou"),
        "reading.instruction.r1": TextEntry("Écoute le son, puis touche la bonne lettre.",
                                            "Listen to the sound, then tap the right letter."),
        "reading.instruction.r2": TextEntry("Assemble les lettres pour former la syllabe.",
                                            "Put the letters together to make the syllable."),
        "reading.instruction.r3": TextEntry("Touche le mot qui correspond à l'image.",
                                            "Tap the word that matches the picture."),
        "reading.prompt.sound": TextEntry("Écoute le son et touche la lettre.", "Listen to the sound and tap the letter."),
        "reading.prompt.sound.keyword": TextEntry("son", "sound"),
        "reading.prompt.syllable": TextEntry("Assemble les lettres pour faire la syllabe.",
                                             "Put the letters together to make the syllable."),
        "reading.prompt.syllable.keyword": TextEntry("syllabe", "syllable"),
        "reading.prompt.word": TextEntry("Touche le mot que tu entends.", "Tap the word you hear."),
        "reading.prompt.word.keyword": TextEntry("mot", "word"),
        "reading.help.r1.look": TextEntry("Regarde bien la forme de chaque lettre.", "Look closely at the shape of each letter."),
        "reading.help.r1.sound": TextEntry("Touche pour réécouter le son.", "Tap to hear the sound again."),
        "reading.help.r2.look": TextEntry("Regarde la première lettre, puis la deuxième.",
                                          "Look at the first letter, then the second."),
        "reading.help.r2.sound": TextEntry("Touche pour réécouter la syllabe.", "Tap to hear the syllable again."),
        "reading.help.r3.look": TextEntry("Cherche « ch » ou « ou » dans le mot.", "Look for “ch” or “ou” in the word."),
        "reading.help.r3.sound": TextEntry("Touche pour réécouter le mot.", "Tap to hear the word again.")
    ]
}
