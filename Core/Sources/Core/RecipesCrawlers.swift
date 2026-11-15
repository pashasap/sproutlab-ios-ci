import Foundation

// Ground dwellers: earthworm, ant, ladybug.
extension Recipe {
    static let earthworm = Recipe(
        id: "earthworm", body: "colour.body.earthworm", placeholder: .egg,
        parts: layered(shadow(0.5, 0.86, 0.4),
            back: [p(.segmentChain, "colour.body.earthworm", [0.14, 0.66, 0.3, 0.56, 0.46, 0.64, 0.62, 0.54])],
            front: [p(.segmentChain, "colour.body.earthworm",
                      [0.12, 0.74, 0.28, 0.64, 0.45, 0.72, 0.6, 0.62, 0.78, 0.68, 0.88, 0.56])
                        .gradient(to: "colour.belly"),
                    p(.ellipse, "colour.belly", [0.6, 0.62, 0.05, 0.07]),
                    p(.seededSpots, "colour.seed", [0.4, 0.7, 0.2]),
                    p(.eye, "colour.eye", [0.87, 0.52, 0.016]).anchored("blink"),
                    p(.eye, "colour.eyeShine", [0.875, 0.515, 0.006])]))

    static let ant = Recipe(
        id: "ant", body: "colour.body.ant", placeholder: .egg,
        parts: layered(shadow(0.5, 0.84, 0.32),
            back: [p(.legs, "colour.body.ant", [0.4, 0.62, 0.3, 0.84, 0.5, 0.62, 0.5, 0.86, 0.6, 0.62, 0.7, 0.84])],
            front: [p(.legs, "colour.body.ant", [0.42, 0.6, 0.28, 0.82, 0.5, 0.6, 0.48, 0.84, 0.58, 0.6, 0.68, 0.82]),
                    p(.ellipse, "colour.body.ant", [0.28, 0.58, 0.14, 0.11]),
                    p(.ellipse, "colour.body.ant", [0.5, 0.56, 0.09, 0.08]),
                    p(.ellipse, "colour.body.ant", [0.72, 0.58, 0.17, 0.13]).gradient(to: "colour.seed"),
                    p(.feelers, "colour.body.ant", [0.2, 0.5, 0.12, 0.3, 0.24, 0.5, 0.2, 0.28]),
                    p(.eye, "colour.eyeShine", [0.22, 0.55, 0.02]).anchored("blink"),
                    p(.eye, "colour.eye", [0.22, 0.55, 0.012])]))

    static let ladybug = Recipe(
        id: "ladybug", body: "colour.body.ladybug", placeholder: .egg,
        parts: layered(shadow(0.5, 0.84, 0.32),
            back: [p(.legs, "colour.spot", [0.34, 0.66, 0.24, 0.84, 0.5, 0.7, 0.5, 0.88, 0.66, 0.66, 0.76, 0.84])],
            front: [p(.ellipse, "colour.spot", [0.5, 0.36, 0.14, 0.1]),
                    p(.ellipse, "colour.body.ladybug", [0.5, 0.58, 0.3, 0.26]).gradient(to: "colour.petal"),
                    p(.spines, "colour.spot", [0.5, 0.34, 0.5, 0.84]),
                    p(.seededSpots, "colour.spot", [0.5, 0.58, 0.22]),
                    p(.feelers, "colour.spot", [0.44, 0.28, 0.36, 0.14, 0.56, 0.28, 0.64, 0.14]),
                    p(.eye, "colour.eyeShine", [0.45, 0.36, 0.022]).anchored("blink"),
                    p(.eye, "colour.eyeShine", [0.55, 0.36, 0.022])]))
}
