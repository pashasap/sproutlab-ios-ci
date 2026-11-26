/// Icon definitions: each `icon.*` key holds the SF Symbol name (same in both languages).
/// The accessibility label of an icon is the key plus `.label`, resolved by `iconLabel`.
extension TextTable {
    static let iconTexts: [String: TextEntry] = Dictionary(
        uniqueKeysWithValues: iconDefinitions.map { ($0.key, TextEntry($0.symbol, $0.symbol)) })

    static func iconLabel(_ key: String) -> TextEntry? {
        guard key.hasSuffix(".label") else { return nil }
        let base = String(key.dropLast(".label".count))
        return iconDefinitions.first { $0.key == base }.map { TextEntry($0.labelFR, $0.labelEN) }
    }

    /// Label of the first icon drawn with the SF Symbol `symbol`, if any.
    static func iconLabel(forSymbol symbol: String) -> TextEntry? {
        iconDefinitions.first { $0.symbol == symbol }.map { TextEntry($0.labelFR, $0.labelEN) }
    }

    static let iconLabelTexts: [String: TextEntry] = Dictionary(uniqueKeysWithValues:
        iconDefinitions.map { ($0.key + ".label", TextEntry($0.labelFR, $0.labelEN)) })

    private struct IconDefinition {
        let key: String
        let symbol: String
        let labelFR: String
        let labelEN: String
    }

    private static let iconDefinitions: [IconDefinition] = [
        IconDefinition(key: "icon.lang.fr", symbol: "globe.europe.africa", labelFR: "Drapeau français", labelEN: "French flag"),
        IconDefinition(key: "icon.lang.en", symbol: "globe.europe.africa.fill", labelFR: "Drapeau anglais", labelEN: "English flag"),
        IconDefinition(key: "icon.music", symbol: "music.note", labelFR: "Musique", labelEN: "Music"),
        // Music off: the same note, drawn with a slash overlay by the view (`music.note.slash` does not exist).
        IconDefinition(key: "icon.music.off", symbol: "music.note", labelFR: "Musique coupée", labelEN: "Music off"),
        IconDefinition(key: "icon.play", symbol: "play.fill", labelFR: "Jouer", labelEN: "Play"),
        IconDefinition(key: "icon.trail", symbol: "map", labelFR: "Sentier des explorateurs", labelEN: "Explorer trail"),
        IconDefinition(key: "icon.math", symbol: "number", labelFR: "Mathématiques", labelEN: "Math"),
        IconDefinition(key: "icon.hear", symbol: "ear", labelFR: "Écouter", labelEN: "Hear"),
        IconDefinition(key: "icon.back", symbol: "arrow.left.circle.fill", labelFR: "Retour", labelEN: "Back"),
        IconDefinition(key: "icon.summary.back", symbol: "arrow.uturn.backward.circle.fill",
                       labelFR: "Retour au sentier", labelEN: "Back to the trail"),
        IconDefinition(key: "icon.completed", symbol: "checkmark.circle.fill", labelFR: "Niveau terminé", labelEN: "Level completed"),
        IconDefinition(key: "icon.star", symbol: "star.fill", labelFR: "Étoile", labelEN: "Star"),
        IconDefinition(key: "icon.counting", symbol: "circle.grid.3x3.fill", labelFR: "Compter", labelEN: "Counting"),
        IconDefinition(key: "icon.hand", symbol: "hand.raised.fill", labelFR: "Accueillir", labelEN: "Welcome"),
        IconDefinition(key: "icon.pan.left", symbol: "play.fill",
                       labelFR: "Aller à gauche", labelEN: "Go left"),
        IconDefinition(key: "icon.pan.right", symbol: "play.fill",
                       labelFR: "Aller à droite", labelEN: "Go right"),
        IconDefinition(key: "icon.journal", symbol: "book.fill", labelFR: "Mon carnet de nature", labelEN: "My nature journal"),
        IconDefinition(key: "icon.bond", symbol: "rectangle.grid.2x2", labelFR: "Faire 10", labelEN: "Make 10"),
        IconDefinition(key: "icon.readingFR", symbol: "book.fill", labelFR: "Lecture en français",
                       labelEN: "French reading"),
        IconDefinition(key: "icon.readingEN", symbol: "book.fill", labelFR: "Lecture en anglais",
                       labelEN: "English reading"),
        IconDefinition(key: "icon.repeat", symbol: "repeat", labelFR: "Répète", labelEN: "Repeat"),
        IconDefinition(key: "icon.robot", symbol: "leaf.fill", labelFR: "Petit Robot", labelEN: "Little Robot"),
        IconDefinition(key: "icon.tenFrameSplit", symbol: "rectangle.split.2x1",
                       labelFR: "Partager la boîte à dix", labelEN: "Split the ten frame"),
        IconDefinition(key: "icon.bridgeTen", symbol: "arrow.turn.down.right",
                       labelFR: "Passer par dix", labelEN: "Bridge through ten"),
        IconDefinition(key: "icon.tensones", symbol: "square.stack.3d.up",
                       labelFR: "Dizaines et unités", labelEN: "Tens and ones")
    ]
}
