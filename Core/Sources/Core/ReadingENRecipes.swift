// Twelve picturable EN2 words, drawn with the same primitives and renderer as the creatures.
// They are shown only after the correct answer and are not part of the creature gallery table.
extension ReadingENBank {
    private static func picture(_ word: String, body: String, _ parts: [RecipePart]) -> Recipe {
        Recipe(id: "en-" + word, body: body, placeholder: .seed, parts: [Recipe.shadow(0.5, 0.92, 0.3)] + parts)
    }

    private static func p(_ primitive: RecipePrimitive, _ colour: String, _ xy: [Double]) -> RecipePart {
        Recipe.p(primitive, colour, xy)
    }

    private static let animals: [Recipe] = [
        picture("cat", body: "colour.petal", [
            p(.ellipse, "colour.petal", [0.5, 0.64, 0.28, 0.2]).gradient(to: "colour.belly"),
            p(.blob, "colour.petal", [0.34, 0.2, 0.66, 0.2, 0.7, 0.5, 0.3, 0.5]),
            p(.spines, "colour.seed", [0.36, 0.22, 0.34, 0.08, 0.46, 0.22, 0.54, 0.22, 0.66, 0.08, 0.64, 0.22]),
            p(.eye, "colour.eye", [0.43, 0.34, 0.02]), p(.eye, "colour.eye", [0.57, 0.34, 0.02])]),
        picture("hen", body: "colour.body.robin", [
            p(.legs, "colour.seed", [0.42, 0.78, 0.4, 0.92, 0.58, 0.78, 0.6, 0.92]),
            p(.ellipse, "colour.body.robin", [0.5, 0.58, 0.28, 0.22]).gradient(to: "colour.belly"),
            p(.blob, "colour.body.robin", [0.26, 0.24, 0.42, 0.2, 0.46, 0.42, 0.28, 0.46]),
            p(.fin, "colour.petal", [0.22, 0.3, 0.08, 0.34, 0.22, 0.38]),
            p(.eye, "colour.eye", [0.32, 0.3, 0.02])]),
        picture("pig", body: "colour.body.axolotl", [
            p(.legs, "colour.body.axolotl", [0.34, 0.74, 0.34, 0.9, 0.66, 0.74, 0.66, 0.9]),
            p(.ellipse, "colour.body.axolotl", [0.5, 0.58, 0.32, 0.2]).gradient(to: "colour.belly"),
            p(.ellipse, "colour.belly", [0.84, 0.54, 0.08, 0.07]),
            p(.eye, "colour.eye", [0.74, 0.46, 0.02])]),
        picture("dog", body: "colour.seed", [
            p(.legs, "colour.seed", [0.3, 0.74, 0.3, 0.92, 0.66, 0.74, 0.66, 0.92]),
            p(.ellipse, "colour.seed", [0.46, 0.58, 0.28, 0.16]).gradient(to: "colour.belly"),
            p(.blob, "colour.seed", [0.66, 0.34, 0.9, 0.38, 0.9, 0.56, 0.66, 0.54]),
            p(.fin, "colour.seed", [0.7, 0.34, 0.66, 0.5, 0.78, 0.46]),
            p(.eye, "colour.eye", [0.8, 0.44, 0.016])])
    ]

    private static let things: [Recipe] = [
        picture("sun", body: "colour.petal", [
            p(.radialGlow, "colour.petal", [0.5, 0.5, 0.4]),
            p(.radialPetals, "colour.petal", [0.5, 0.5, 0.3]),
            p(.ellipse, "colour.petal", [0.5, 0.5, 0.2, 0.2]).gradient(to: "colour.belly")]),
        picture("bus", body: "colour.body.honeybee", [
            p(.ellipse, "colour.body.honeybee", [0.5, 0.5, 0.42, 0.24]),
            p(.ellipse, "colour.glow", [0.3, 0.44, 0.08, 0.08]), p(.ellipse, "colour.glow", [0.5, 0.44, 0.08, 0.08]),
            p(.ellipse, "colour.glow", [0.7, 0.44, 0.08, 0.08]),
            p(.ellipse, "colour.eye", [0.26, 0.76, 0.07, 0.07]), p(.ellipse, "colour.eye", [0.74, 0.76, 0.07, 0.07])]),
        picture("cup", body: "colour.body.mushroom", [
            p(.blob, "colour.body.mushroom", [0.26, 0.3, 0.74, 0.3, 0.66, 0.78, 0.34, 0.78]).gradient(to: "colour.gill"),
            p(.stem, "colour.body.mushroom", [0.74, 0.42, 0.86, 0.5]),
            p(.radialGlow, "colour.eyeShine", [0.36, 0.4, 0.04])]),
        picture("hat", body: "colour.body.butterfly", [
            p(.ellipse, "colour.body.butterfly", [0.5, 0.7, 0.4, 0.07]),
            p(.blob, "colour.body.butterfly", [0.3, 0.7, 0.36, 0.3, 0.64, 0.3, 0.7, 0.7]).gradient(to: "colour.gill"),
            p(.segmentChain, "colour.petal", [0.32, 0.62, 0.68, 0.62])]),
        picture("bed", body: "colour.body.mushroom", [
            p(.ellipse, "colour.body.mushroom", [0.5, 0.6, 0.4, 0.12]),
            p(.ellipse, "colour.belly", [0.3, 0.5, 0.12, 0.08]),
            p(.stem, "colour.seed", [0.12, 0.4, 0.12, 0.84]), p(.stem, "colour.seed", [0.88, 0.6, 0.88, 0.84])]),
        picture("pin", body: "colour.body.poppy", [
            p(.stem, "colour.silhouette", [0.5, 0.3, 0.5, 0.9]),
            p(.ellipse, "colour.body.poppy", [0.5, 0.22, 0.12, 0.12]).gradient(to: "colour.belly")]),
        picture("log", body: "colour.seed", [
            p(.ellipse, "colour.seed", [0.5, 0.58, 0.4, 0.18]).gradient(to: "colour.body.snail"),
            p(.ellipse, "colour.belly", [0.84, 0.58, 0.1, 0.16]),
            p(.leafBlade, "colour.leaf", [0.4, 0.4, 0.5, 0.26, 0.56, 0.4])]),
        picture("net", body: "colour.leaf", [
            p(.stem, "colour.seed", [0.3, 0.9, 0.62, 0.4]),
            p(.ellipse, "colour.leaf", [0.68, 0.3, 0.2, 0.2]).gradient(to: "colour.glow"),
            p(.segmentChain, "colour.stem", [0.52, 0.3, 0.84, 0.3])])
    ]

    /// One recipe per picturable EN2 reveal word; the picture key of an item is the recipe id.
    public static let recipes: [Recipe] = animals + things
}
