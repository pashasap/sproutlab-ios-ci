import Foundation

// Plants and fungus. Points are x,y pairs in the unit square; see RecipePrimitive for the shapes.
extension Recipe {
    static let sunflower = Recipe(
        id: "sunflower", body: "colour.body.sunflower", placeholder: .seed,
        parts: layered(shadow(0.5, 0.94, 0.22),
            back: [p(.leafBlade, "colour.leaf", [0.5, 0.88, 0.28, 0.72, 0.34, 0.6, 0.5, 0.78]),
                   p(.radialPetals, "colour.body.sunflower", [0.5, 0.38, 0.36])],
            front: [p(.stem, "colour.stem", [0.5, 0.93, 0.5, 0.55]),
                    p(.leafBlade, "colour.leaf", [0.5, 0.8, 0.72, 0.66, 0.82, 0.72, 0.62, 0.84]),
                    p(.radialPetals, "colour.body.sunflower", [0.5, 0.38, 0.34]).gradient(to: "colour.petal"),
                    p(.ellipse, "colour.seed", [0.5, 0.38, 0.14, 0.14]),
                    p(.seededSpots, "colour.petal", [0.5, 0.38, 0.11]),
                    p(.eye, "colour.eye", [0.45, 0.36, 0.015]).anchored("blink"),
                    p(.eye, "colour.eye", [0.55, 0.36, 0.015]).anchored("blink")]))

    static let fern = Recipe(
        id: "fern", body: "colour.body.fern", placeholder: .seed,
        parts: layered(shadow(0.5, 0.94, 0.2),
            back: [p(.frond, "colour.body.fern", [0.5, 0.92, 0.3, 0.6, 0.18, 0.3]),
                   p(.frond, "colour.body.fern", [0.5, 0.92, 0.7, 0.6, 0.82, 0.3])],
            front: [p(.stem, "colour.stem", [0.5, 0.93, 0.5, 0.2]),
                    p(.frond, "colour.body.fern", [0.5, 0.92, 0.38, 0.55, 0.3, 0.2]).gradient(to: "colour.leaf"),
                    p(.frond, "colour.body.fern", [0.5, 0.92, 0.62, 0.55, 0.7, 0.2]).gradient(to: "colour.leaf"),
                    p(.frond, "colour.body.fern", [0.5, 0.9, 0.5, 0.5, 0.5, 0.08]),
                    p(.spiralShell, "colour.leaf", [0.5, 0.14, 0.05]),
                    p(.eye, "colour.eye", [0.46, 0.7, 0.014]).anchored("blink"),
                    p(.eye, "colour.eye", [0.54, 0.7, 0.014]).anchored("blink")]))

    static let glowingMushroom = Recipe(
        id: "glowing-mushroom", body: "colour.body.mushroom", placeholder: .seed,
        parts: layered(shadow(0.5, 0.94, 0.24),
            back: [p(.ellipse, "colour.body.mushroom", [0.36, 0.5, 0.2, 0.14]),
                   p(.stem, "colour.gill", [0.36, 0.92, 0.36, 0.55])],
            front: [p(.radialGlow, "colour.glow", [0.5, 0.45, 0.46]),
                    p(.stem, "colour.gill", [0.5, 0.93, 0.5, 0.5]),
                    p(.ellipse, "colour.body.mushroom", [0.5, 0.45, 0.34, 0.24]).gradient(to: "colour.glow"),
                    p(.blob, "colour.gill", [0.2, 0.52, 0.5, 0.58, 0.8, 0.52, 0.5, 0.54]),
                    p(.seededSpots, "colour.glow", [0.5, 0.38, 0.22]),
                    p(.eye, "colour.eye", [0.44, 0.7, 0.016]).anchored("blink"),
                    p(.eye, "colour.eye", [0.56, 0.7, 0.016]).anchored("blink")]))
}
