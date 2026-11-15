import Foundation

// Honeybee, snail, poppy, dandelion, robin and cricket.
extension Recipe {
    static let honeybee = Recipe(
        id: "honeybee", body: "colour.body.honeybee", placeholder: .chrysalis,
        parts: layered(shadow(0.5, 0.9, 0.24),
            back: [p(.wingPair, "colour.eyeShine", [0.5, 0.4, 0.1, 0.2, 0.2, 0.5])],
            front: [p(.ellipse, "colour.body.honeybee", [0.5, 0.6, 0.26, 0.17]).gradient(to: "colour.spot"),
                    p(.spines, "colour.spot", [0.42, 0.46, 0.42, 0.74]),
                    p(.spines, "colour.spot", [0.58, 0.46, 0.58, 0.74]),
                    p(.wingPair, "colour.eyeShine", [0.5, 0.42, 0.08, 0.16, 0.16, 0.5]),
                    p(.feelers, "colour.spot", [0.24, 0.54, 0.18, 0.4, 0.26, 0.52, 0.24, 0.38]),
                    p(.eye, "colour.eye", [0.26, 0.58, 0.016]).anchored("blink")]))

    static let snail = Recipe(
        id: "snail", body: "colour.body.snail", placeholder: .egg,
        parts: layered(shadow(0.5, 0.86, 0.38),
            back: [p(.segmentChain, "colour.belly", [0.1, 0.78, 0.3, 0.74, 0.5, 0.78])],
            front: [p(.segmentChain, "colour.belly", [0.08, 0.8, 0.3, 0.76, 0.56, 0.8, 0.8, 0.7]),
                    p(.spiralShell, "colour.body.snail", [0.5, 0.5, 0.26]).gradient(to: "colour.seed"),
                    p(.feelers, "colour.belly", [0.82, 0.68, 0.84, 0.5, 0.9, 0.68, 0.94, 0.5]),
                    p(.eye, "colour.eye", [0.84, 0.5, 0.014]).anchored("blink")]))

    static let poppy = Recipe(
        id: "poppy", body: "colour.body.poppy", placeholder: .seed,
        parts: layered(shadow(0.5, 0.92, 0.2),
            back: [p(.leafBlade, "colour.leaf", [0.5, 0.9, 0.3, 0.7, 0.2, 0.8])],
            front: [p(.stem, "colour.stem", [0.5, 0.9, 0.5, 0.5]),
                    p(.leafBlade, "colour.leaf", [0.5, 0.78, 0.7, 0.62, 0.8, 0.74]),
                    p(.radialPetals, "colour.body.poppy", [0.5, 0.36, 0.22]),
                    p(.radialGlow, "colour.spot", [0.5, 0.36, 0.05]),
                    p(.eye, "colour.eyeShine", [0.46, 0.34, 0.012]).anchored("blink")]))

    static let dandelion = Recipe(
        id: "dandelion", body: "colour.body.dandelion", placeholder: .seed,
        parts: layered(shadow(0.5, 0.92, 0.2),
            back: [p(.frond, "colour.leaf", [0.5, 0.9, 0.3, 0.76, 0.16, 0.84])],
            front: [p(.stem, "colour.stem", [0.5, 0.9, 0.5, 0.46]),
                    p(.frond, "colour.leaf", [0.5, 0.88, 0.72, 0.74, 0.86, 0.84]),
                    p(.radialPetals, "colour.body.dandelion", [0.5, 0.34, 0.2]),
                    p(.radialGlow, "colour.petal", [0.5, 0.34, 0.07]),
                    p(.eye, "colour.eye", [0.5, 0.34, 0.012]).anchored("blink")]))

    static let robin = Recipe(
        id: "robin", body: "colour.body.robin", placeholder: .egg,
        parts: layered(shadow(0.5, 0.9, 0.26),
            back: [p(.legs, "colour.seed", [0.44, 0.78, 0.4, 0.9, 0.58, 0.78, 0.6, 0.9])],
            front: [p(.ellipse, "colour.seed", [0.5, 0.58, 0.28, 0.24]).gradient(to: "colour.belly"),
                    p(.ellipse, "colour.body.robin", [0.38, 0.6, 0.12, 0.14]),
                    p(.fin, "colour.seed", [0.74, 0.56, 0.96, 0.62, 0.78, 0.7]),
                    p(.blob, "colour.seed", [0.3, 0.34, 0.4, 0.24, 0.5, 0.34, 0.4, 0.46]),
                    p(.spines, "colour.petal", [0.28, 0.36, 0.14, 0.38]),
                    p(.eye, "colour.eyeShine", [0.36, 0.34, 0.03]).anchored("blink"),
                    p(.eye, "colour.eye", [0.36, 0.34, 0.015])]))

    static let cricket = Recipe(
        id: "cricket", body: "colour.body.cricket", placeholder: .egg,
        parts: layered(shadow(0.5, 0.88, 0.3),
            back: [p(.legs, "colour.body.cricket", [0.5, 0.64, 0.7, 0.4, 0.76, 0.88, 0.56, 0.66])],
            front: [p(.legs, "colour.body.cricket", [0.4, 0.66, 0.3, 0.86, 0.5, 0.68, 0.46, 0.88]),
                    p(.ellipse, "colour.body.cricket", [0.5, 0.58, 0.28, 0.14]).gradient(to: "colour.seed"),
                    p(.wingPair, "colour.seed", [0.52, 0.52, 0.8, 0.36, 0.3, 0.6]),
                    p(.blob, "colour.body.cricket", [0.2, 0.46, 0.3, 0.4, 0.34, 0.54, 0.22, 0.62]),
                    p(.feelers, "colour.body.cricket", [0.22, 0.44, 0.1, 0.2, 0.26, 0.42, 0.28, 0.16]),
                    p(.eye, "colour.eyeShine", [0.24, 0.5, 0.022]).anchored("blink"),
                    p(.eye, "colour.eye", [0.24, 0.5, 0.012])]))

    static let meadowTable: [Recipe] = [honeybee, snail, poppy, dandelion, robin, cricket]
}
