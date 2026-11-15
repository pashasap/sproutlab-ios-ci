import SwiftUI
import Core

/// Sky gradient and drifting particles of one `TerrariumFrame`; gradient fills only.
struct TerrariumSkyView: View {
    let frame: TerrariumFrame
    let scheme: ColourScheme

    var body: some View {
        Canvas { context, size in
            let sky = frame.sky(scheme)
            let gradient = Gradient(colors: [Self.colour(sky.top), Self.colour(sky.bottom)])
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            let tint = Self.colour(frame.tint(scheme))
            for particle in frame.particles {
                let rect = CGRect(x: particle.x * size.width, y: particle.y * size.height,
                                  width: particle.size, height: particle.size)
                context.fill(Path(ellipseIn: rect), with: .color(tint.opacity(particle.opacity)))
            }
        }
        .accessibilityHidden(true)
    }

    static func colour(_ value: RGBColour) -> Color {
        Palette.colour(value)
    }
}
