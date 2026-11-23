import SwiftUI
import UIKit
import Core

/// Colours defined in code, each with a light and a dark value.
enum Palette {
    static let background = dynamic(light: 0xF4FAF0, dark: 0x16221A)
    static let card = dynamic(light: 0xFFFFFF, dark: 0x22332A)
    static let ink = dynamic(light: 0x1E3A28, dark: 0xEAF5EC)
    static let accent = dynamic(light: 0x2E7D4F, dark: 0x7BD69A)
    static let onAccent = dynamic(light: 0xFFFFFF, dark: 0x10261A)
    static let star = dynamic(light: 0xB87400, dark: 0xFFCF5A)
    static let dot = dynamic(light: 0xD1495B, dark: 0xFF8FA0)
    static let locked = dynamic(light: 0x5F6F64, dark: 0xA9B8AE)

    /// Activity identity colours from the Core token, each with a light and a dark value.
    static func activity(_ token: ActivityColourToken) -> Color {
        let light = ActivityPalette.colour(token, .light)
        let dark = ActivityPalette.colour(token, .dark)
        return Color(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.r, green: c.g, blue: c.b, alpha: 1)
        })
    }

    /// Core colour token to colour; unknown tokens fall back to the ink colour.
    static func token(_ token: String) -> Color {
        switch token {
        case "colour.green": return dynamic(light: 0x1B7F3B, dark: 0x6FDC8C)
        case "colour.locked": return locked
        case "colour.accent": return accent
        case "colour.suggested": return star
        case "colour.review": return dynamic(light: 0xB35C00, dark: 0xFFB454)
        case "colour.dot": return dot
        case "colour.mark": return ink
        case "colour.markHalo": return card
        case "colour.math", "colour.counting", "colour.bond": return accent
        default: return coreToken(token) ?? ink
        }
    }

    /// Colours whose light and dark values Core defines (for example the reading lane).
    private static func coreToken(_ token: String) -> Color? {
        guard let light = ColourTokens.value(token, .light), let dark = ColourTokens.value(token, .dark) else { return nil }
        return Color(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.r, green: c.g, blue: c.b, alpha: 1)
        })
    }

    /// A Core colour value as a SwiftUI colour: the one place such values become `Color`.
    static func colour(_ value: RGBColour) -> Color {
        Color(red: value.r, green: value.g, blue: value.b)
    }

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? rgb(dark) : rgb(light)
        })
    }

    private static func rgb(_ value: UInt32) -> UIColor {
        UIColor(red: CGFloat((value >> 16) & 0xFF) / 255,
                green: CGFloat((value >> 8) & 0xFF) / 255,
                blue: CGFloat(value & 0xFF) / 255, alpha: 1)
    }
}
