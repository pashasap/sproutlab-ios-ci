import Foundation

/// Drawing primitives. A renderer maps each case to a shape; recipes are pure data in a unit square.
public enum RecipePrimitive: String, CaseIterable, Sendable {
    case ellipse, blob, segmentChain, wingPair, legs, feelers, eye, spines
    case spiralShell, radialPetals, stem, leafBlade, frond, fin, seededSpots, radialGlow
}

public struct RecipePoint: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// Scale about a pivot, used for depth and the tap pose.
struct RecipeScale {
    var x: Double
    var y: Double
    var pivot: RecipePoint
}

public struct RecipePart: Equatable, Sendable {
    public var primitive: RecipePrimitive
    public var colourToken: String
    public var gradientToken: String?
    public var anchor: String?
    public var points: [RecipePoint]
    /// Radius in the unit square for the centred primitives (eye, spots, petals, glow, spiral).
    public var radius: Double?

    public init(_ primitive: RecipePrimitive, _ colourToken: String, points: [RecipePoint]) {
        self.primitive = primitive
        self.colourToken = colourToken
        self.points = points
    }

    func gradient(to token: String) -> RecipePart {
        var copy = self
        copy.gradientToken = token
        return copy
    }

    func anchored(_ name: String) -> RecipePart {
        var copy = self
        copy.anchor = name
        return copy
    }

    func scaled(_ scale: RecipeScale) -> RecipePart {
        var copy = self
        copy.radius = radius.map { $0 * (scale.x + scale.y) / 2 }
        copy.points = points.map {
            RecipePoint(x: min(1, max(0, scale.pivot.x + ($0.x - scale.pivot.x) * scale.x)),
                        y: min(1, max(0, scale.pivot.y + ($0.y - scale.pivot.y) * scale.y)))
        }
        return copy
    }

    func recoloured(_ token: String) -> RecipePart {
        var copy = self
        copy.colourToken = token
        copy.gradientToken = nil
        return copy
    }
}

public struct Recipe: Equatable, Sendable {
    public static let maxParts = 40

    public var id: String
    public var parts: [RecipePart]
    public var symbolNames: [String]
    public var nameKey: String
    public var bodyColourToken: String
    public var placeholder: RingSilhouette

    public init(id: String, body: String, placeholder: RingSilhouette, parts: [RecipePart]) {
        self.id = id
        self.parts = parts
        self.symbolNames = [ChromeCatalog.symbolName(for: .star)]
        self.nameKey = "recipe.\(id).name"
        self.bodyColourToken = body
        self.placeholder = placeholder
    }
}
