import Foundation

// Robot, seed and sprout: code-drawn shapes. The robot has no face part and no speech.
extension Recipe {
    static let robot = Recipe(
        id: "robot", body: "colour.body.robot", placeholder: .seed,
        parts: layered(shadow(0.5, 0.92, 0.3),
            back: [p(.legs, "colour.body.robot", [0.36, 0.78, 0.3, 0.92, 0.64, 0.78, 0.7, 0.92])],
            front: [p(.ellipse, "colour.body.robot", [0.5, 0.62, 0.28, 0.24]).gradient(to: "colour.belly"),
                    p(.blob, "colour.body.robot", [0.3, 0.4, 0.5, 0.26, 0.7, 0.4, 0.5, 0.5]),
                    p(.stem, "colour.stem", [0.5, 0.28, 0.5, 0.14]),
                    p(.radialGlow, "colour.glow", [0.5, 0.12, 0.05]),
                    p(.seededSpots, "colour.glow", [0.5, 0.62, 0.1])]))

    static let seed = Recipe(
        id: "seed", body: "colour.body.seed", placeholder: .seed,
        parts: layered(shadow(0.5, 0.88, 0.2),
            back: [],
            front: [p(.ellipse, "colour.body.seed", [0.5, 0.66, 0.2, 0.2]).gradient(to: "colour.belly"),
                    p(.seededSpots, "colour.seed", [0.5, 0.66, 0.1])]))

    static let sprout = Recipe(
        id: "sprout", body: "colour.body.sprout", placeholder: .seed,
        parts: layered(shadow(0.5, 0.9, 0.22),
            back: [p(.leafBlade, "colour.leaf", [0.5, 0.6, 0.3, 0.4, 0.2, 0.5])],
            front: [p(.stem, "colour.stem", [0.5, 0.88, 0.5, 0.5]),
                    p(.leafBlade, "colour.body.sprout", [0.5, 0.52, 0.72, 0.32, 0.84, 0.46]),
                    p(.leafBlade, "colour.body.sprout", [0.5, 0.58, 0.28, 0.4, 0.16, 0.52]),
                    p(.ellipse, "colour.body.seed", [0.5, 0.9, 0.12, 0.05])]))

    static let robotTable: [Recipe] = [robot, seed, sprout]
}

extension TextTable {
    static let robotRecipeTexts: [String: TextEntry] = [
        "recipe.robot.name": TextEntry("le petit robot", "the little robot"),
        "recipe.seed.name": TextEntry("la graine", "the seed"),
        "recipe.sprout.name": TextEntry("la pousse", "the sprout")
    ]
}
