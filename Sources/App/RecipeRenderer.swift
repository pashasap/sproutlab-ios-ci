import SwiftUI
import Core

/// Draws any Core recipe through a switch over the primitives. No per-creature drawing code.
struct RecipeRenderer: View {
    let recipe: Recipe
    let scheme: ColourScheme

    var body: some View {
        Canvas { context, size in
            let painter = RecipePainter(size: size, scheme: scheme)
            var layer = context
            for part in recipe.parts {
                painter.paint(part, in: &layer)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Maps unit-square recipe parts to paths and Core colour tokens to colours.
struct RecipePainter {
    let size: CGSize
    let scheme: ColourScheme

    private var unit: CGFloat { min(size.width, size.height) }

    func paint(_ part: RecipePart, in context: inout GraphicsContext) {
        let shading = shading(for: part)
        switch part.primitive {
        case .ellipse: context.fill(ellipse(part), with: shading)
        case .blob: context.fill(smoothClosed(part.points), with: shading)
        case .segmentChain: stroke(chain(part.points), width: 0.07, shading, &context)
        case .wingPair: context.fill(wings(part), with: shading)
        case .legs: stroke(pairs(part.points), width: 0.025, shading, &context)
        case .feelers: stroke(pairs(part.points), width: 0.015, shading, &context)
        case .eye: context.fill(disc(part, fallback: 0.02), with: shading)
        case .spines: stroke(pairs(part.points), width: 0.012, shading, &context)
        case .spiralShell: stroke(spiral(part), width: 0.012, shading, &context)
        case .radialPetals: context.fill(petals(part), with: shading)
        case .stem: stroke(chain(part.points), width: 0.04, shading, &context)
        case .leafBlade: context.fill(smoothClosed(part.points), with: shading)
        case .frond: stroke(curve(part.points), width: 0.045, shading, &context)
        case .fin: context.fill(smoothClosed(part.points), with: shading)
        case .seededSpots: context.fill(spots(part), with: shading)
        case .radialGlow: context.fill(disc(part, fallback: 0.3), with: glow(for: part))
        }
    }

    // MARK: Colour

    func colour(_ token: String) -> Color {
        guard let value = ColourTokens.value(token, scheme) else { return .gray }
        return Palette.colour(value)
    }

    private func shading(for part: RecipePart) -> GraphicsContext.Shading {
        let first = colour(part.colourToken)
        guard let token = part.gradientToken else { return .color(first) }
        return .linearGradient(Gradient(colors: [first, colour(token)]),
                               startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: size.height))
    }

    private func glow(for part: RecipePart) -> GraphicsContext.Shading {
        let centre = point(part.points.first)
        let tint = colour(part.colourToken)
        return .radialGradient(Gradient(colors: [tint.opacity(0.55), tint.opacity(0)]),
                               center: centre, startRadius: 0, endRadius: length(part.radius, 0.3))
    }

    // MARK: Geometry

    private func point(_ value: RecipePoint?) -> CGPoint {
        CGPoint(x: (value?.x ?? 0) * size.width, y: (value?.y ?? 0) * size.height)
    }

    private func length(_ value: Double?, _ fallback: Double) -> CGFloat {
        CGFloat(value ?? fallback) * unit
    }

    private func stroke(_ path: Path, width: Double, _ shading: GraphicsContext.Shading,
                        _ context: inout GraphicsContext) {
        let style = StrokeStyle(lineWidth: CGFloat(width) * unit, lineCap: .round, lineJoin: .round)
        context.stroke(path, with: shading, style: style)
    }

    private func ellipse(_ part: RecipePart) -> Path {
        let centre = point(part.points.first)
        let radii = point(part.points.dropFirst().first)
        return Path(ellipseIn: CGRect(x: centre.x - radii.x, y: centre.y - radii.y,
                                      width: radii.x * 2, height: radii.y * 2))
    }

    private func disc(_ part: RecipePart, fallback: Double) -> Path {
        let centre = point(part.points.first)
        let radius = length(part.radius, fallback)
        return Path(ellipseIn: CGRect(x: centre.x - radius, y: centre.y - radius,
                                      width: radius * 2, height: radius * 2))
    }

    private func chain(_ points: [RecipePoint]) -> Path {
        var path = Path()
        for (index, value) in points.enumerated() {
            index == 0 ? path.move(to: point(value)) : path.addLine(to: point(value))
        }
        return path
    }

    /// Each consecutive pair of points is one stroke (base to tip).
    private func pairs(_ points: [RecipePoint]) -> Path {
        var path = Path()
        for index in stride(from: 0, to: points.count - 1, by: 2) {
            path.move(to: point(points[index]))
            path.addLine(to: point(points[index + 1]))
        }
        return path
    }

    private func curve(_ points: [RecipePoint]) -> Path {
        guard points.count >= 3 else { return chain(points) }
        var path = Path()
        path.move(to: point(points[0]))
        path.addQuadCurve(to: point(points[2]), control: point(points[1]))
        return path
    }

    /// A closed outline through the midpoints of its edges, so corners read as soft curves.
    private func smoothClosed(_ points: [RecipePoint]) -> Path {
        guard points.count >= 3 else { return chain(points) }
        let all = points.map { point($0) }
        var path = Path()
        path.move(to: mid(all[all.count - 1], all[0]))
        for index in all.indices {
            path.addQuadCurve(to: mid(all[index], all[(index + 1) % all.count]), control: all[index])
        }
        path.closeSubpath()
        return path
    }

    private func mid(_ one: CGPoint, _ two: CGPoint) -> CGPoint {
        CGPoint(x: (one.x + two.x) / 2, y: (one.y + two.y) / 2)
    }

    /// Points: body centre, upper wing tip, lower wing tip; mirrored across the vertical axis.
    private func wings(_ part: RecipePart) -> Path {
        guard part.points.count >= 3 else { return Path() }
        var path = Path()
        for mirrored in [false, true] {
            let flip = { (value: RecipePoint) -> CGPoint in
                mirrored ? CGPoint(x: size.width - point(value).x, y: point(value).y) : point(value)
            }
            let centre = flip(part.points[0])
            path.move(to: centre)
            path.addQuadCurve(to: flip(part.points[1]), control: CGPoint(x: centre.x, y: flip(part.points[1]).y))
            path.addQuadCurve(to: flip(part.points[2]), control: CGPoint(x: flip(part.points[1]).x, y: flip(part.points[2]).y))
            path.addQuadCurve(to: centre, control: CGPoint(x: centre.x, y: flip(part.points[2]).y))
        }
        return path
    }

    private func spiral(_ part: RecipePart) -> Path {
        let centre = point(part.points.first)
        let radius = length(part.radius, 0.05)
        var path = Path()
        for step in 0...40 {
            let fraction = Double(step) / 40
            let angle = fraction * 4 * Double.pi
            let reach = radius * CGFloat(fraction)
            let next = CGPoint(x: centre.x + reach * CGFloat(cos(angle)), y: centre.y + reach * CGFloat(sin(angle)))
            step == 0 ? path.move(to: next) : path.addLine(to: next)
        }
        return path
    }

    private func petals(_ part: RecipePart) -> Path {
        let centre = point(part.points.first)
        let radius = length(part.radius, 0.3)
        var path = Path()
        for index in 0..<12 {
            let angle = Double(index) / 12 * 2 * Double.pi
            let petal = Path(ellipseIn: CGRect(x: radius * 0.45, y: -radius * 0.14,
                                               width: radius * 0.55, height: radius * 0.28))
            let turn = CGAffineTransform(translationX: centre.x, y: centre.y).rotated(by: CGFloat(angle))
            path.addPath(petal, transform: turn)
        }
        return path
    }

    /// Deterministic dots on a golden-angle spread, so the same recipe always looks the same.
    private func spots(_ part: RecipePart) -> Path {
        let centre = point(part.points.first)
        let radius = length(part.radius, 0.2)
        var path = Path()
        for index in 1...7 {
            let angle = Double(index) * 2.399963
            let reach = radius * CGFloat((Double(index) / 8).squareRoot())
            let spot = CGPoint(x: centre.x + reach * CGFloat(cos(angle)), y: centre.y + reach * CGFloat(sin(angle)))
            let dot = radius * 0.12
            path.addEllipse(in: CGRect(x: spot.x - dot, y: spot.y - dot, width: dot * 2, height: dot * 2))
        }
        return path
    }
}
