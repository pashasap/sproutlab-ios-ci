import Foundation

public enum ColourScheme: Sendable, CaseIterable {
    case light, dark
}

public struct RGBColour: Equatable, Sendable {
    public var r: Double
    public var g: Double
    public var b: Double

    public init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    /// HSV saturation: 0 for greys, 1 for a pure hue.
    public var saturation: Double {
        let high = max(r, g, b)
        return high <= 0 ? 0 : (high - min(r, g, b)) / high
    }

    func mixed(toward other: RGBColour, _ amount: Double) -> RGBColour {
        RGBColour(r: r + (other.r - r) * amount, g: g + (other.g - g) * amount,
                  b: b + (other.b - b) * amount)
    }
}

/// WCAG 2 relative luminance and contrast ratio.
public enum Contrast {
    static func linear(_ value: Double) -> Double {
        value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }

    public static func luminance(_ c: RGBColour) -> Double {
        0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b)
    }

    public static func ratio(_ a: RGBColour, _ b: RGBColour) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }
}

/// Core colour tokens with a light and a dark value. Views render these values.
public enum ColourTokens {
    struct Swatch: Sendable {
        let light: RGBColour
        let dark: RGBColour

        init(_ light: (Double, Double, Double), _ dark: (Double, Double, Double)) {
            self.light = RGBColour(r: light.0, g: light.1, b: light.2)
            self.dark = RGBColour(r: dark.0, g: dark.1, b: dark.2)
        }
    }

    public static let gardenGround = "colour.garden.ground"
    /// Standard secondary text colour; light and dark values are resolved in `value`.
    public static let secondaryText = "colour.text.secondary"
    /// The round progress label ("Question 1 sur 5") uses the secondary text token.
    public static let progressLabel = secondaryText
    public static let silhouette = "colour.silhouette"
    public static let shadow = "colour.shadow"
    public static let backSuffix = ".back"
    /// How far a back-layer colour moves toward the ground (softer, no blur).
    static let backMix = 0.3

    static let palette: [String: Swatch] = [
        gardenGround: Swatch((0.95, 0.93, 0.84), (0.08, 0.13, 0.09)),
        silhouette: Swatch((0.45, 0.45, 0.45), (0.70, 0.70, 0.70)),
        shadow: Swatch((0.55, 0.50, 0.40), (0.02, 0.04, 0.03)),
        "colour.leaf": Swatch((0.15, 0.45, 0.20), (0.40, 0.75, 0.40)),
        "colour.stem": Swatch((0.20, 0.40, 0.15), (0.45, 0.70, 0.35)),
        "colour.petal": Swatch((0.85, 0.60, 0.05), (1.00, 0.85, 0.30)),
        "colour.seed": Swatch((0.35, 0.22, 0.10), (0.65, 0.48, 0.30)),
        "colour.belly": Swatch((0.90, 0.75, 0.60), (0.80, 0.65, 0.50)),
        "colour.eye": Swatch((0.08, 0.08, 0.10), (0.05, 0.05, 0.07)),
        "colour.eyeShine": Swatch((1, 1, 1), (1, 1, 1)),
        "colour.spot": Swatch((0.10, 0.10, 0.12), (0.10, 0.10, 0.12)),
        "colour.glow": Swatch((0.55, 0.95, 0.80), (0.50, 1.00, 0.80)),
        "colour.gill": Swatch((0.85, 0.80, 0.90), (0.75, 0.70, 0.85)),
        "colour.readingFR": Swatch((0.45, 0.22, 0.60), (0.78, 0.62, 0.92)),
        "colour.readingEN": Swatch((0.05, 0.38, 0.45), (0.55, 0.85, 0.90)),
        "colour.wing": Swatch((0.95, 0.55, 0.10), (1.00, 0.70, 0.25)),
        // Creature body colours are identical in light and dark and sit in a mid-luminance band
        // (about 0.15 to 0.19) so they keep 3:1 against every light and dark ground.
        "colour.body.sunflower": same(0.66, 0.42, 0.00),
        "colour.body.earthworm": same(0.68, 0.34, 0.34),
        "colour.body.ant": same(0.58, 0.38, 0.30),
        "colour.body.fern": same(0.15, 0.50, 0.20),
        "colour.body.ladybug": same(0.86, 0.22, 0.20),
        "colour.body.treefrog": same(0.18, 0.52, 0.22),
        "colour.body.mushroom": same(0.20, 0.45, 0.60),
        "colour.body.axolotl": same(0.70, 0.30, 0.45),
        "colour.body.butterfly": same(0.35, 0.42, 0.85),
        "colour.body.honeybee": same(0.62, 0.42, 0.00),
        "colour.body.snail": same(0.62, 0.40, 0.25),
        "colour.body.poppy": same(0.85, 0.15, 0.12),
        "colour.body.dandelion": same(0.60, 0.40, 0.00),
        "colour.body.robin": same(0.80, 0.30, 0.10),
        "colour.body.cricket": same(0.35, 0.50, 0.15),
        "colour.body.robot": same(0.35, 0.45, 0.60),
        "colour.body.sprout": same(0.18, 0.50, 0.20),
        "colour.body.seed": same(0.60, 0.40, 0.25)
    ]

    private static func same(_ r: Double, _ g: Double, _ b: Double) -> Swatch {
        Swatch((r, g, b), (r, g, b))
    }

    /// Every recipe token, including the generated softer `.back` variants.
    public static let allTokens: Set<String> = {
        let keys = Set(palette.keys)
        return keys.union(keys.filter { $0 != gardenGround }.map { $0 + backSuffix })
    }()

    public static func value(_ token: String, _ scheme: ColourScheme) -> RGBColour? {
        if token.hasSuffix(backSuffix) {
            let base = String(token.dropLast(backSuffix.count))
            guard base != gardenGround, let colour = value(base, scheme),
                  let ground = value(gardenGround, scheme) else { return nil }
            return colour.mixed(toward: ground, backMix)
        }
        if token == secondaryText {
            return scheme == .light ? RGBColour(r: 0.30, g: 0.30, b: 0.30)
                                    : RGBColour(r: 0.75, g: 0.78, b: 0.75)
        }
        guard let swatch = palette[token] else { return nil }
        return scheme == .light ? swatch.light : swatch.dark
    }
}
