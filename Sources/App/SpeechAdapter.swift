import AVFoundation
import Foundation
import Core

/// Speaks prompts with AVSpeechSynthesizer using the best installed on-device voice; no network TTS.
final class SpeechAdapter: SpeechService, @unchecked Sendable {
    private lazy var synthesizer = AVSpeechSynthesizer()

    func speak(voiceTag: String, text: String) throws -> SpeechOutcome {
        guard let voice = bestVoice(tag: voiceTag) else { return .voiceMissing }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
        return .spoken
    }

    func voiceName(tag: String) -> String? {
        if ProcessInfo.processInfo.arguments.contains("-auditStop") { return nil }
        return bestVoice(tag: tag)?.name
    }

    /// The chooser's result for the language of `tag`, for the diagnostics row.
    func voiceChoice(tag: String) -> VoiceChoice? {
        if ProcessInfo.processInfo.arguments.contains("-auditStop") { return nil }
        return VoiceChooser.choose(from: candidates(), language: tag.hasPrefix("fr") ? .fr : .en)
    }

    private func candidates() -> [VoiceCandidate] {
        AVSpeechSynthesisVoice.speechVoices().map {
            VoiceCandidate(name: $0.name, language: $0.language, quality: Self.quality($0.quality))
        }
    }

    private static func quality(_ quality: AVSpeechSynthesisVoiceQuality) -> VoiceQuality {
        switch quality {
        case .premium: return .premium
        case .enhanced: return .enhanced
        default: return .defaultQuality
        }
    }

    private func bestVoice(tag: String) -> AVSpeechSynthesisVoice? {
        let language: Language = tag.hasPrefix("fr") ? .fr : .en
        if let choice = VoiceChooser.choose(from: candidates(), language: language),
           let voice = AVSpeechSynthesisVoice.speechVoices().first(where: {
               $0.name == choice.name && $0.language.hasPrefix(VoiceChooser.languagePrefix(language))
           }) {
            return voice
        }
        return AVSpeechSynthesisVoice(language: tag)
    }
}
