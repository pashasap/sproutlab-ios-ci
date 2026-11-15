public enum ReadingItemKind: Equatable, Sendable {
    case phoneme, grapheme, syllable, word
}

/// How an answer was given; only a tap or a kit placement is decoding evidence.
public enum AnswerSource: CaseIterable, Equatable, Sendable {
    case tap, kit, spoken, listenOnly
}

public struct ReadingItem: Equatable, Sendable {
    public let kind: ReadingItemKind
    public let text: String

    public init(kind: ReadingItemKind, text: String) {
        self.kind = kind
        self.text = text
    }

    /// Evidence rule: spoken and listen-only answers never count as decoding.
    public static func countsAsDecoding(source: AnswerSource) -> Bool {
        switch source {
        case .tap, .kit: return true
        case .spoken, .listenOnly: return false
        }
    }
}

public enum ReadingSpeech {
    public static let voiceTag = "fr-FR"

    /// Text to speak for a syllable or a word; nil for a bare phoneme or grapheme.
    public static func utterance(for item: ReadingItem) -> String? {
        switch item.kind {
        case .syllable, .word: return item.text.isEmpty ? nil : item.text
        case .phoneme, .grapheme: return nil
        }
    }
}

/// The Tap to Hear control: speaks only inside `tapToHear()`.
public final class ReadingHearControl: Sendable {
    private let item: ReadingItem
    private let speech: any SpeechService

    public init(item: ReadingItem, speech: any SpeechService) {
        self.item = item
        self.speech = speech
    }

    public func tapToHear() {
        guard let text = ReadingSpeech.utterance(for: item) else { return }
        _ = try? speech.speak(voiceTag: ReadingSpeech.voiceTag, text: text)
    }
}
