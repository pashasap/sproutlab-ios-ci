import Foundation

// Twelve picturable R2 words, drawn with the same primitives and renderer as the creatures.
extension Recipe {
    /// Text-table key of the spoken description of this recipe.
    public var accessibilityKey: String { "recipe.\(id).description" }

    private static func picture(_ id: String, body: String, _ parts: [RecipePart]) -> Recipe {
        Recipe(id: id, body: body, placeholder: .seed, parts: [shadow(0.5, 0.92, 0.3)] + parts)
    }

    static let readingMoon = picture("moon", body: "colour.petal", [
        p(.radialGlow, "colour.petal", [0.5, 0.5, 0.34]),
        p(.ellipse, "colour.petal", [0.5, 0.5, 0.26, 0.26]).gradient(to: "colour.belly"),
        p(.seededSpots, "colour.belly", [0.58, 0.44, 0.1]),
        p(.eye, "colour.eye", [0.44, 0.5, 0.02])])

    static let readingRose = picture("rose", body: "colour.body.poppy", [
        p(.stem, "colour.stem", [0.5, 0.9, 0.5, 0.45]),
        p(.leafBlade, "colour.leaf", [0.5, 0.74, 0.74, 0.6, 0.8, 0.72]),
        p(.radialPetals, "colour.body.poppy", [0.5, 0.34, 0.24]),
        p(.radialGlow, "colour.petal", [0.5, 0.34, 0.06])])

    static let readingDress = picture("dress", body: "colour.body.axolotl", [
        p(.blob, "colour.body.axolotl", [0.5, 0.3, 0.74, 0.88, 0.26, 0.88]).gradient(to: "colour.belly"),
        p(.stem, "colour.body.axolotl", [0.42, 0.3, 0.42, 0.1]),
        p(.stem, "colour.body.axolotl", [0.58, 0.3, 0.58, 0.1]),
        p(.segmentChain, "colour.petal", [0.4, 0.42, 0.6, 0.42])])

    static let readingPipe = picture("pipe", body: "colour.seed", [
        p(.ellipse, "colour.seed", [0.7, 0.4, 0.14, 0.16]).gradient(to: "colour.body.snail"),
        p(.stem, "colour.seed", [0.14, 0.74, 0.62, 0.5]),
        p(.radialGlow, "colour.belly", [0.7, 0.2, 0.06]),
        p(.radialGlow, "colour.belly", [0.76, 0.1, 0.04])])

    static let readingTipi = picture("tipi", body: "colour.belly", [
        p(.blob, "colour.belly", [0.5, 0.14, 0.82, 0.88, 0.18, 0.88]).gradient(to: "colour.petal"),
        p(.blob, "colour.seed", [0.5, 0.5, 0.58, 0.88, 0.42, 0.88]),
        p(.spines, "colour.seed", [0.44, 0.14, 0.38, 0.02, 0.56, 0.14, 0.62, 0.02])])

    static let readingDodo = picture("dodo", body: "colour.body.cricket", [
        p(.legs, "colour.seed", [0.42, 0.78, 0.4, 0.92, 0.58, 0.78, 0.6, 0.92]),
        p(.ellipse, "colour.body.cricket", [0.5, 0.6, 0.28, 0.22]).gradient(to: "colour.belly"),
        p(.fin, "colour.leaf", [0.74, 0.56, 0.94, 0.5, 0.78, 0.68]),
        p(.blob, "colour.body.cricket", [0.22, 0.28, 0.4, 0.22, 0.46, 0.4, 0.28, 0.46]),
        p(.fin, "colour.petal", [0.16, 0.32, 0.04, 0.36, 0.18, 0.4]),
        p(.eye, "colour.eye", [0.32, 0.32, 0.02])])

    static let readingLlama = picture("llama", body: "colour.belly", [
        p(.legs, "colour.seed", [0.34, 0.74, 0.32, 0.92, 0.62, 0.74, 0.64, 0.92]),
        p(.ellipse, "colour.belly", [0.5, 0.62, 0.26, 0.16]).gradient(to: "colour.petal"),
        p(.stem, "colour.belly", [0.72, 0.56, 0.78, 0.2]),
        p(.blob, "colour.belly", [0.72, 0.1, 0.9, 0.16, 0.86, 0.3, 0.7, 0.28]),
        p(.spines, "colour.seed", [0.74, 0.12, 0.72, 0.02, 0.82, 0.12, 0.84, 0.02]),
        p(.eye, "colour.eye", [0.82, 0.18, 0.016])])

    static let readingDune = picture("dune", body: "colour.petal", [
        p(.blob, "colour.petal", [0.0, 0.88, 0.4, 0.4, 0.7, 0.62, 1.0, 0.88]).gradient(to: "colour.belly"),
        p(.blob, "colour.belly", [0.3, 0.9, 0.7, 0.6, 1.0, 0.9]),
        p(.frond, "colour.leaf", [0.2, 0.84, 0.18, 0.6, 0.1, 0.52]),
        p(.radialGlow, "colour.petal", [0.8, 0.16, 0.1])])

    static let readingTuba = picture("tuba", body: "colour.petal", [
        p(.segmentChain, "colour.petal", [0.3, 0.84, 0.3, 0.46, 0.56, 0.4, 0.62, 0.7]),
        p(.ellipse, "colour.petal", [0.7, 0.6, 0.22, 0.22]).gradient(to: "colour.belly"),
        p(.radialGlow, "colour.eyeShine", [0.7, 0.6, 0.08]),
        p(.stem, "colour.seed", [0.3, 0.46, 0.3, 0.12])])

    static let readingSofa = picture("sofa", body: "colour.body.mushroom", [
        p(.ellipse, "colour.body.mushroom", [0.5, 0.42, 0.34, 0.18]),
        p(.ellipse, "colour.body.mushroom", [0.5, 0.66, 0.4, 0.14]).gradient(to: "colour.gill"),
        p(.ellipse, "colour.body.mushroom", [0.14, 0.62, 0.08, 0.16]),
        p(.ellipse, "colour.body.mushroom", [0.86, 0.62, 0.08, 0.16]),
        p(.legs, "colour.seed", [0.2, 0.8, 0.2, 0.9, 0.8, 0.8, 0.8, 0.9])])

    static let readingPond = picture("pond", body: "colour.body.mushroom", [
        p(.ellipse, "colour.body.mushroom", [0.5, 0.64, 0.42, 0.22]).gradient(to: "colour.glow"),
        p(.leafBlade, "colour.leaf", [0.36, 0.64, 0.5, 0.54, 0.48, 0.66]),
        p(.stem, "colour.stem", [0.8, 0.7, 0.82, 0.2]),
        p(.stem, "colour.stem", [0.88, 0.7, 0.9, 0.3]),
        p(.radialGlow, "colour.eyeShine", [0.6, 0.6, 0.05])])

    static let readingMule = picture("mule", body: "colour.seed", [
        p(.legs, "colour.seed", [0.32, 0.74, 0.3, 0.92, 0.62, 0.74, 0.64, 0.92]),
        p(.ellipse, "colour.seed", [0.5, 0.58, 0.28, 0.16]).gradient(to: "colour.belly"),
        p(.blob, "colour.seed", [0.7, 0.4, 0.92, 0.46, 0.9, 0.62, 0.68, 0.58]),
        p(.spines, "colour.seed", [0.72, 0.42, 0.7, 0.24, 0.8, 0.42, 0.84, 0.26]),
        p(.eye, "colour.eye", [0.8, 0.5, 0.016]),
        p(.fin, "colour.seed", [0.22, 0.52, 0.06, 0.6, 0.2, 0.7])])

    /// One row per picturable R2 bank word; the picture key of a bank item is the recipe id.
    public static let readingTable: [Recipe] = [
        readingMoon, readingRose, readingDress, readingPipe, readingTipi, readingDodo,
        readingLlama, readingDune, readingTuba, readingSofa, readingPond, readingMule
    ]
}

extension TextTable {
    private static let readingRecipeWords: [(id: String, nameFR: String, nameEN: String, fr: String, en: String)] = [
        ("moon", "la lune", "the moon", "Une lune ronde et jaune, avec une tache claire.",
         "A round yellow moon with a pale patch."),
        ("rose", "la rose", "the rose", "Une rose rouge sur sa tige verte, avec une feuille.",
         "A red rose on a green stem, with one leaf."),
        ("dress", "la robe", "the dress", "Une robe rose en forme de cloche, avec deux bretelles.",
         "A pink bell-shaped dress with two straps."),
        ("pipe", "la pipe", "the pipe", "Une pipe brune avec un fourneau rond et un peu de fumée.",
         "A brown pipe with a round bowl and a little smoke."),
        ("tipi", "le tipi", "the tipi", "Un tipi, une tente pointue avec des perches en haut.",
         "A tipi, a pointed tent with poles sticking out of the top."),
        ("dodo", "le dodo", "the dodo", "Un dodo, gros oiseau rond à bec crochu, sur deux pattes.",
         "A dodo, a plump round bird with a hooked beak, on two legs."),
        ("llama", "le lama", "the llama", "Un lama au long cou, avec deux oreilles pointues.",
         "A llama with a long neck and two pointed ears."),
        ("dune", "la dune", "the dune", "Une dune de sable doré avec une touffe d'herbe.",
         "A golden sand dune with a tuft of grass."),
        ("tuba", "le tuba", "the tuba", "Un tuba doré avec un grand pavillon rond.",
         "A golden tuba with a big round bell."),
        ("sofa", "le sofa", "the sofa", "Un sofa bleu avec un dossier et deux accoudoirs.",
         "A blue sofa with a backrest and two armrests."),
        ("pond", "la mare", "the pond", "Une mare d'eau bleue avec un nénuphar et des roseaux.",
         "A pond of blue water with a lily pad and reeds."),
        ("mule", "la mule", "the mule", "Une mule brune à longues oreilles, sur quatre pattes.",
         "A brown mule with long ears, standing on four legs.")
    ]

    /// Names and spoken descriptions of the reading recipes, in French and English.
    static let readingRecipeTexts: [String: TextEntry] = {
        var texts: [String: TextEntry] = [:]
        for row in readingRecipeWords {
            texts["recipe.\(row.id).name"] = TextEntry(row.nameFR, row.nameEN)
            texts["recipe.\(row.id).description"] = TextEntry(row.fr, row.en)
        }
        return texts
    }()
}
