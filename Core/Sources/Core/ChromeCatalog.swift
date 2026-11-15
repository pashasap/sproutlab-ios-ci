public enum ChromeScreen: Sendable, Hashable, CaseIterable {
    case welcome
    case trail
    case question
}

public enum ChromeFlag: Sendable, Hashable {
    case fr
    case gb
}

public enum ChromeIconKind: Sendable, Hashable {
    case flag(ChromeFlag)
    case note
    case noteSlashed
    case play
    case trail
    case math
    case ear
    case back
    case check
    case star
}

public struct ChromeIcon: Sendable, Equatable {
    public static let minimumTarget: Double = 56

    public let kind: ChromeIconKind
    public let accessibilityLabel: String
    public let minTarget: Double
}

public struct LanguageControl: Sendable, Equatable {
    public let flag: ChromeFlag
    public let text: String
}

public struct StarTotal: Sendable, Equatable {
    public let icon: ChromeIcon
    public let text: String
}

public struct BrandIcon: Sendable, Equatable {
    public let fileName: String
    public let seededRelativePath: String

    public static let standard = BrandIcon(fileName: "AppIcon.png",
                                           seededRelativePath: "Sources/App/Resources/AppIcon.png")
}

public struct ChromeTitle: Sendable, Equatable {
    public let text: String
    public let brand: BrandIcon
}

public struct ChromeAction: Sendable, Equatable {
    public let identifier: String
}

public enum TitleTapAction: Sendable, Equatable {
    case home
}

/// The one definition of how the title (full text or icon-only) reacts: tap, hold, label, identifier.
public struct TitleInteraction: Sendable, Equatable {
    public let tapAction: TitleTapAction
    public let holdSeconds: Double
    public let accessibilityLabel: String
    public let identifier: String
}

public enum ChromeCatalog {
    public static func titleInteraction(language: Language) -> TitleInteraction {
        TitleInteraction(tapAction: .home, holdSeconds: TitleHold.threshold,
                         accessibilityLabel: TextTable.string("a11y.title", language),
                         identifier: SproutIdentifier.title)
    }

    static func make(_ kind: ChromeIconKind, key: String, _ language: Language) -> ChromeIcon {
        ChromeIcon(kind: kind, accessibilityLabel: TextTable.string(key, language),
                   minTarget: ChromeIcon.minimumTarget)
    }

    public static func icon(_ kind: ChromeIconKind, language: Language) -> ChromeIcon {
        make(kind, key: labelKey(kind), language)
    }

    static func labelKey(_ kind: ChromeIconKind) -> String {
        switch kind {
        case .flag(.fr): return "icon.lang.fr.label"
        case .flag(.gb): return "icon.lang.en.label"
        case .note: return "chrome.music.on.label"
        case .noteSlashed: return "chrome.music.off.label"
        case .play: return "icon.play.label"
        case .trail: return "icon.trail.label"
        case .math: return "icon.math.label"
        case .ear: return "icon.hear.label"
        case .back: return "icon.back.label"
        case .check: return "icon.completed.label"
        case .star: return "icon.star.label"
        }
    }

    public static func icons(for screen: ChromeScreen, language: Language, musicOn: Bool) -> [ChromeIcon] {
        var kinds: [ChromeIconKind] = [.flag(.fr), .flag(.gb), musicOn ? .note : .noteSlashed]
        switch screen {
        case .welcome: kinds += [.play]
        case .trail: kinds += [.trail, .math, .back, .star]
        case .question: kinds += [.ear, .back, .star]
        }
        return kinds.map { icon($0, language: language) }
    }

    public static func languageControl(showing language: Language) -> LanguageControl {
        LanguageControl(flag: language == .fr ? .fr : .gb, text: language.rawValue.uppercased())
    }

    public static func musicIcon(on: Bool, language: Language) -> ChromeIcon {
        icon(on ? .note : .noteSlashed, language: language)
    }

    public static func starTotal(_ stars: Int, language: Language) -> StarTotal {
        StarTotal(icon: icon(.star, language: language), text: String(stars))
    }

    public static func title(language: Language) -> ChromeTitle {
        ChromeTitle(text: TextTable.string("welcome.title", language), brand: .standard)
    }

    public static func actions(for screen: ChromeScreen) -> [ChromeAction] {
        var ids = ["language", "music"]
        switch screen {
        case .welcome: ids += ["play", "home"]
        case .trail, .question: ids += ["back", "home"]
        }
        return ids.map { ChromeAction(identifier: $0) }
    }
}

extension TextTable {
    static let chromeTexts: [String: TextEntry] = [
        "chrome.music.on.label": TextEntry("Musique activée", "Music on"),
        "chrome.music.off.label": TextEntry("Musique coupée", "Music off"),
        "celebration.text": TextEntry("Trois étoiles pour toi !", "Three stars for you!"),
        "chrome.terrarium.label": TextEntry("Ouvrir le terrarium", "Open the terrarium")
    ]
}
