/// Quality tier of an on-device voice, best first.
public enum VoiceQuality: Int, Equatable, Sendable {
    case premium = 0, enhanced, defaultQuality

    public var label: String {
        switch self {
        case .premium: return "Premium"
        case .enhanced: return "Enhanced"
        case .defaultQuality: return "Default"
        }
    }
}

public struct VoiceCandidate: Equatable, Sendable {
    public var name: String
    /// BCP-47 tag such as "fr-FR".
    public var language: String
    public var quality: VoiceQuality

    public init(name: String, language: String, quality: VoiceQuality) {
        self.name = name
        self.language = language
        self.quality = quality
    }
}

public struct VoiceChoice: Equatable, Sendable {
    public var name: String
    public var tier: VoiceQuality
    public var needsBetterVoiceHint: Bool

    public init(name: String, tier: VoiceQuality, needsBetterVoiceHint: Bool) {
        self.name = name
        self.tier = tier
        self.needsBetterVoiceHint = needsBetterVoiceHint
    }
}

/// Picks the best installed on-device voice for a language; no network voices.
public enum VoiceChooser {
    public static func languagePrefix(_ language: Language) -> String { language == .fr ? "fr" : "en" }

    public static func choose(from candidates: [VoiceCandidate], language: Language) -> VoiceChoice? {
        let prefix = languagePrefix(language)
        let matching = candidates.filter { candidate in
            let tag = candidate.language.lowercased()
            return tag == prefix || tag.hasPrefix(prefix + "-") || tag.hasPrefix(prefix + "_")
        }
        let best = matching.min { lhs, rhs in
            (lhs.quality.rawValue, lhs.name, lhs.language) < (rhs.quality.rawValue, rhs.name, rhs.language)
        }
        guard let best else { return nil }
        return VoiceChoice(name: best.name, tier: best.quality, needsBetterVoiceHint: best.quality == .defaultQuality)
    }
}
