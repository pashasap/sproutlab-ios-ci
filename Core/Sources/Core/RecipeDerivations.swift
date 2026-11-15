import Foundation

extension Recipe {
    static let tapSquash = RecipeScale(x: 1.06, y: 0.92, pivot: RecipePoint(x: 0.5, y: 0.9))
    static let backScale = RecipeScale(x: 0.92, y: 0.92, pivot: RecipePoint(x: 0.5, y: 0.55))

    /// Short squash-and-settle pose shown when the child taps the creature.
    public var tapPose: Recipe {
        var pose = self
        pose.parts = parts.map { $0.scaled(Recipe.tapSquash) }
        return pose
    }

    /// Desaturated stand-in for a creature that has not arrived yet.
    public var silhouette: Recipe {
        var grey = self
        grey.parts = parts.map { $0.colourToken == ColourTokens.shadow ? $0 : $0.recoloured(ColourTokens.silhouette) }
        grey.bodyColourToken = ColourTokens.silhouette
        return grey
    }

    static func p(_ primitive: RecipePrimitive, _ colour: String, _ xy: [Double]) -> RecipePart {
        let points = stride(from: 0, to: xy.count - 1, by: 2).map { RecipePoint(x: xy[$0], y: xy[$0 + 1]) }
        var part = RecipePart(primitive, colour, points: points)
        if xy.count % 2 == 1 { part.radius = xy[xy.count - 1] }
        return part
    }

    /// A flattened contact shadow: a flat ellipse on the ground, no blur.
    static func shadow(_ cx: Double, _ cy: Double, _ rx: Double) -> RecipePart {
        p(.ellipse, ColourTokens.shadow, [cx, cy, rx, 0.03])
    }

    /// Depth by layering: shadow first, then smaller softer back parts that overlap the front ones.
    static func layered(_ shadow: RecipePart, back: [RecipePart], front: [RecipePart]) -> [RecipePart] {
        let softened = back.map { part -> RecipePart in
            var soft = part.scaled(backScale)
            if !soft.colourToken.hasSuffix(ColourTokens.backSuffix) {
                soft.colourToken += ColourTokens.backSuffix
            }
            return soft
        }
        return [shadow] + softened + front
    }
}
