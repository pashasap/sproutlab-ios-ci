extension TextTable {
    static let appShellTexts: [String: TextEntry] = [
        "a11y.question.format": TextEntry("Question {n} sur {total}", "Question {n} of {total}"),
        "a11y.result.format": TextEntry("Bravo ! {n} étoiles gagnées.", "Well done! You earned {n} stars."),
        "a11y.result.one": TextEntry("Bravo ! 1 étoile gagnée.", "Well done! You earned 1 star."),
        "a11y.celebration": TextEntry("Célébration", "Celebration"),
        "a11y.dots": TextEntry("Points à compter", "Dots to count"),
        "a11y.level.locked": TextEntry("Niveau verrouillé", "Level locked"),
        "diag.version": TextEntry("Version", "Version"),
        "diag.build": TextEntry("Build", "Build"),
        "diag.launch": TextEntry("Lancement", "Launch time"),
        "diag.frames": TextEntry("Images perdues", "Dropped frames"),
        "diag.save": TextEntry("Dernière sauvegarde", "Last save"),
        "diag.audio": TextEntry("Moteur audio", "Audio engine"),
        "diag.voice.fr": TextEntry("Voix française", "French voice"),
        "diag.voice.en": TextEntry("Voix anglaise", "English voice"),
        "diag.voice.active": TextEntry("Voix choisie", "Chosen voice"),
        "diag.voice.hint": TextEntry("Conseil", "Tip"),
        "diag.close": TextEntry("Fermer", "Close"),
        "diag.developer": TextEntry("Mode développeur", "Developer Mode"),
        "diag.developer.on": TextEntry("Activé", "On"),
        "diag.developer.off": TextEntry("Désactivé", "Off"),
        "diag.reset": TextEntry("Réinitialiser toute la progression", "Reset All Progress"),
        "diag.reset.title": TextEntry("Tout réinitialiser ?", "Reset everything?"),
        "diag.reset.message": TextEntry("Les étoiles, les niveaux terminés et le terrarium seront effacés.",
                                        "Stars, finished levels and the terrarium will be erased."),
        "diag.reset.confirm": TextEntry("Réinitialiser", "Reset"),
        "diag.reset.cancel": TextEntry("Annuler", "Cancel")
    ].merging(droppedFrameTexts) { first, _ in first }

    static let droppedFrameTexts: [String: TextEntry] = [
        "diag.frames.terrarium.dawn": TextEntry("Terrarium : aube", "Terrarium: dawn"),
        "diag.frames.terrarium.day": TextEntry("Terrarium : jour", "Terrarium: day"),
        "diag.frames.terrarium.dusk": TextEntry("Terrarium : crépuscule", "Terrarium: dusk"),
        "diag.frames.terrarium.night": TextEntry("Terrarium : nuit", "Terrarium: night"),
        "diag.frames.gallery.dawn": TextEntry("Galerie : aube", "Gallery: dawn"),
        "diag.frames.gallery.day": TextEntry("Galerie : jour", "Gallery: day"),
        "diag.frames.gallery.dusk": TextEntry("Galerie : crépuscule", "Gallery: dusk"),
        "diag.frames.gallery.night": TextEntry("Galerie : nuit", "Gallery: night")
    ]
}
