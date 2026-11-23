import Foundation

// Tree frog, axolotl and butterfly.
extension Recipe {
    static let treeFrog = Recipe(
        id: "tree-frog", body: "colour.body.treefrog", placeholder: .egg,
        parts: layered(shadow(0.5, 0.9, 0.34),
            back: [p(.legs, "colour.body.treefrog", [0.3, 0.7, 0.14, 0.88, 0.7, 0.7, 0.86, 0.88])],
            front: [p(.legs, "colour.body.treefrog", [0.3, 0.74, 0.18, 0.9, 0.7, 0.74, 0.82, 0.9]),
                    p(.ellipse, "colour.body.treefrog", [0.5, 0.64, 0.3, 0.22]).gradient(to: "colour.leaf"),
                    p(.ellipse, "colour.belly", [0.5, 0.72, 0.18, 0.12]),
                    p(.blob, "colour.body.treefrog", [0.26, 0.5, 0.5, 0.36, 0.74, 0.5, 0.5, 0.58]),
                    p(.seededSpots, "colour.leaf", [0.5, 0.6, 0.2]),
                    p(.eye, "colour.eyeShine", [0.38, 0.38, 0.05]).anchored("blink"),
                    p(.eye, "colour.eye", [0.38, 0.38, 0.025]),
                    p(.eye, "colour.eyeShine", [0.62, 0.38, 0.05]),
                    p(.eye, "colour.eye", [0.62, 0.38, 0.025])]))

    static let axolotl = Recipe(
        id: "axolotl", body: "colour.body.axolotl", placeholder: .egg,
        parts: layered(shadow(0.5, 0.88, 0.38),
            back: [p(.fin, "colour.body.axolotl", [0.7, 0.66, 0.96, 0.58, 0.94, 0.8]),
                   p(.legs, "colour.body.axolotl", [0.36, 0.72, 0.28, 0.88, 0.56, 0.74, 0.5, 0.88])],
            front: [p(.fin, "colour.body.axolotl", [0.5, 0.5, 0.6, 0.4, 0.8, 0.5]).gradient(to: "colour.belly"),
                    p(.ellipse, "colour.body.axolotl", [0.5, 0.64, 0.3, 0.14]).gradient(to: "colour.belly"),
                    p(.fin, "colour.body.axolotl", [0.74, 0.64, 0.96, 0.5, 0.98, 0.72]),
                    p(.blob, "colour.body.axolotl", [0.18, 0.5, 0.3, 0.38, 0.46, 0.5, 0.3, 0.7]),
                    p(.spines, "colour.petal", [0.2, 0.44, 0.1, 0.34, 0.2, 0.5, 0.08, 0.5]),
                    p(.eye, "colour.eye", [0.28, 0.48, 0.02]).anchored("blink"),
                    p(.eye, "colour.eyeShine", [0.285, 0.475, 0.007]),
                    p(.seededSpots, "colour.belly", [0.55, 0.62, 0.2])]))

    static let butterfly = Recipe(
        id: "butterfly", body: "colour.body.butterfly", placeholder: .chrysalis,
        parts: layered(shadow(0.5, 0.92, 0.2),
            back: [p(.wingPair, "colour.body.butterfly", [0.5, 0.5, 0.06, 0.2, 0.2, 0.6])],
            front: [p(.wingPair, "colour.body.butterfly", [0.5, 0.5, 0.04, 0.16, 0.18, 0.62])
                        .gradient(to: "colour.wing"),
                    p(.seededSpots, "colour.eyeShine", [0.26, 0.38, 0.12]),
                    p(.seededSpots, "colour.eyeShine", [0.74, 0.38, 0.12]),
                    p(.segmentChain, "colour.spot", [0.5, 0.36, 0.5, 0.5, 0.5, 0.7]),
                    p(.feelers, "colour.spot", [0.48, 0.34, 0.4, 0.14, 0.52, 0.34, 0.6, 0.14]),
                    p(.eye, "colour.eyeShine", [0.5, 0.38, 0.016]).anchored("blink")]))

    /// One row per resident, in arrival order.
    public static let table: [Recipe] = [
        sunflower, earthworm, ant, fern, ladybug, treeFrog, glowingMushroom, axolotl, butterfly
    ] + meadowTable + robotTable
}
