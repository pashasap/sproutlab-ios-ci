import AVFoundation
import Foundation
import Core

/// Speaks prompts with AVSpeechSynthesizer; used only from the main thread by the view models.
final class SpeechAdapter: SpeechService, @unchecked Sendable {
    private lazy var synthesizer = AVSpeechSynthesizer()

    func speak(voiceTag: String, text: String) throws -> SpeechOutcome {
        guard let voice = AVSpeechSynthesisVoice(language: voiceTag) else { return .voiceMissing }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
        return .spoken
    }

    func voiceName(tag: String) -> String? {
        if ProcessInfo.processInfo.arguments.contains("-auditStop") { return nil }
        return AVSpeechSynthesisVoice(language: tag)?.name
    }
}
