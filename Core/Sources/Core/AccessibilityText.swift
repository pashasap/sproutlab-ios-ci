import Foundation

/// Localised spoken texts for VoiceOver, built from TextTable templates.
public enum AccessibilityText {
    public static func questionAnnouncement(number: Int, of total: Int, language: Language) -> String {
        TextTable.string("a11y.question.format", language)
            .replacingOccurrences(of: "{n}", with: String(number))
            .replacingOccurrences(of: "{total}", with: String(total))
    }

    /// The visible and spoken progress label, e.g. "Question 1 sur 5".
    public static func progressLabel(number: Int, of total: Int, language: Language) -> String {
        questionAnnouncement(number: number, of: total, language: language)
    }

    public static func roundResult(stars: Int, language: Language) -> String {
        let key = stars == 1 ? "a11y.result.one" : "a11y.result.format"
        return TextTable.string(key, language)
            .replacingOccurrences(of: "{n}", with: String(stars))
    }

    public static func starsTotal(_ total: Int, language: Language) -> String {
        TextTable.string("a11y.stars", language) + ": " + String(total)
    }
}
