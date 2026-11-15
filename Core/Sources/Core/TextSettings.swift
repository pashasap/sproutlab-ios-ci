extension TextTable {
    static let settingsTexts: [String: TextEntry] = [
        "settings.language": TextEntry("Langue", "Language"),
        "settings.language.fr": TextEntry("Français", "French"),
        "settings.language.en": TextEntry("Anglais", "English"),
        "settings.music": TextEntry("Musique", "Music"),
        "settings.diagnostics": TextEntry("Diagnostics", "Diagnostics")
    ]

    static let noticeTexts: [String: TextEntry] = [
        "notice.save.missing": TextEntry("Nouvelle partie : aucune sauvegarde trouvée.",
                                         "New game: no saved progress found."),
        "notice.save.corrupt": TextEntry("La sauvegarde est illisible. On repart de zéro.",
                                         "The saved progress could not be read. Starting fresh."),
        "notice.save.unsupported": TextEntry("La sauvegarde vient d'une version plus récente.",
                                             "The saved progress comes from a newer version."),
        "notice.save-missing": TextEntry("Nouvelle partie : aucune sauvegarde trouvée.",
                                         "New game: no saved progress found."),
        "notice.save-corrupt": TextEntry("La sauvegarde est illisible. On repart de zéro.",
                                         "The saved progress could not be read. Starting fresh."),
        "notice.save-unsupported": TextEntry("La sauvegarde vient d'une version plus récente.",
                                             "The saved progress comes from a newer version."),
        "notice.save-failed": TextEntry("La sauvegarde a échoué. Le jeu continue.",
                                        "Saving failed. You can keep playing."),
        "notice.voice-missing": TextEntry("La voix n'est pas disponible sur cet appareil.",
                                          "The voice is not available on this device."),
        "notice.voice.missing": TextEntry("La voix n'est pas disponible sur cet appareil.",
                                          "The voice is not available on this device.")
    ]

    static let accessibilityTexts: [String: TextEntry] = [
        "a11y.play": TextEntry("Jouer", "Play"),
        "a11y.language": TextEntry("Changer de langue", "Change language"),
        "a11y.music": TextEntry("Activer ou couper la musique", "Turn music on or off"),
        "a11y.stars": TextEntry("Total d'étoiles", "Total stars"),
        "a11y.speak": TextEntry("Écouter la question", "Hear the question"),
        "a11y.choice": TextEntry("Réponse", "Answer"),
        "a11y.question.new": TextEntry("Nouvelle question", "New question"),
        "a11y.round.result": TextEntry("Manche terminée, 3 étoiles", "Round complete, 3 stars"),
        "a11y.level": TextEntry("Niveau de maths", "Math level"),
        "a11y.back": TextEntry("Retour au sentier", "Back to the trail"),
        "a11y.title": TextEntry("SproutLab, appui long pour les diagnostics",
                                "SproutLab, press and hold for diagnostics")
    ]
}
