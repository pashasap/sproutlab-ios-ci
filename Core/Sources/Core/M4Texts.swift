extension TextTable {
    /// Child text of the Math M4 level; prompts are 1 to 3 words, each with its keyword.
    static let m4Texts: [String: TextEntry] = [
        "trail.level.math-m4-tens-ones.title": TextEntry("Dizaines et unités", "Tens and ones"),
        "m4.prompt.bundle": TextEntry("Compte les paquets", "Count the bundles"),
        "m4.prompt.bundle.keyword": TextEntry("paquets", "bundles"),
        "m4.prompt.build": TextEntry("Construis le nombre", "Build the number"),
        "m4.prompt.build.keyword": TextEntry("nombre", "number"),
        "m4.prompt.match": TextEntry("Trouve le modèle", "Find the model"),
        "m4.prompt.match.keyword": TextEntry("modèle", "model"),
        "m4.speech.bundle": TextEntry("Regarde les paquets de dix et les unités.", "Look at the bundles of ten and the loose units."),
        "m4.speech.build": TextEntry("Ajoute les dizaines puis les unités.", "Add the tens, then the ones."),
        "m4.speech.match": TextEntry("Cherche l'image qui montre le même nombre.", "Look for the picture that shows the same number."),
        "m4.hint": TextEntry("Compte dix pour chaque paquet, puis ajoute les unités.", "Count ten for each bundle, then add the loose units."),
        "m4.help.trays": TextEntry("Ouvre les plateaux des dizaines et des unités.", "Open the tens tray and the ones tray."),
        "m4.help.values": TextEntry("Compte dix pour chaque paquet.", "Count ten for each bundle."),
        "m4.help.digit": TextEntry("Construis la part d'un chiffre.", "Build one digit's part."),
        "m4.button.tens": TextEntry("Dizaines", "Tens"),
        "m4.button.ones": TextEntry("Unités", "Ones"),
        "m4.equiv.model": TextEntry("%1 paquets de dix et %2 unités", "%1 tens and %2 ones"),
        "m4.view.trays": TextEntry("Plateaux ouverts", "Trays open"),
        "m4.view.bundle": TextEntry("Paquet de dix", "Bundle of ten"),
        "m4.view.contribution": TextEntry("Dizaines : %1", "Tens: %1")
    ]
}
