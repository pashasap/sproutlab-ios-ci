/// A deterministic shuffle that never returns the words already in order.
public enum SentenceShuffle {
    /// The words in a shuffled order for `seed`; the result is a permutation and never the input order.
    public static func shuffled(_ words: [String], seed: UInt64) -> [String] {
        guard words.count > 1 else { return words }
        var rng = SeededRandom(seed: seed &+ 0x5348)
        var out = words
        var i = out.count - 1
        while i > 0 {
            out.swapAt(i, rng.below(i + 1))
            i -= 1
        }
        if out == words {
            // Rotate by one: still a permutation, never the visible order.
            out = Array(words.dropFirst()) + [words[0]]
        }
        return out
    }
}

/// Picks the items of a round without repeating an item, and builds what the view draws.
public enum SentenceSelector {
    /// The details that tell the two scenes of a sentence apart; the value is never a word of its sentence.
    static let detailAlternatives: [String: String] = [
        "noir": "brun", "petit": "grand", "ronde": "plate", "fine": "épaisse",
        "rond": "plat", "sous": "sur", "sur": "sous", "mure": "verte"
    ]

    /// The English details of the scene kind; every value differs from the word it replaces.
    static let englishDetailAlternatives: [String: String] = [
        "red": "blue", "big": "small", "wet": "dry", "hot": "cold", "fat": "thin"
    ]

    static let misconceptions = ["mot d'un autre sens", "mot qui ressemble", "mot du mauvais groupe"]

    /// The English mistake labels; a listening child never sees them in French.
    static let englishMisconceptions = ["a word with another meaning", "a word that looks alike",
                                        "a word from the wrong group"]

    static func bank(_ language: Language) -> [SentenceItem] {
        language == .fr ? FrenchSentenceBank.items : EnglishSentenceBank.items
    }

    static func alternatives(_ language: Language) -> [String: String] {
        language == .fr ? detailAlternatives : englishDetailAlternatives
    }

    static func labels(_ language: Language) -> [String] {
        language == .fr ? misconceptions : englishMisconceptions
    }

    /// Up to `count` distinct items, fixed for a seed; the loop is bounded by the bank size.
    public static func round(seed: UInt64, count: Int, language: Language = .fr) -> [SentenceItem] {
        guard count > 0 else { return [] }
        var rng = SeededRandom(seed: seed &+ 0x5236)
        let shuffled = rng.shuffled(bank(language))
        return Array(shuffled.prefix(min(count, shuffled.count)))
    }

    public static func presentation(for item: SentenceItem, seed: UInt64,
                                    language: Language = .fr) -> SentencePresentation {
        switch item.kind {
        case .complete: return complete(of: item, seed: seed, language: language)
        case .scene: return scene(of: item, seed: seed, language: language)
        case .order: return order(of: item, seed: seed)
        }
    }

    static func complete(of item: SentenceItem, seed: UInt64, language: Language) -> SentencePresentation {
        var rng = SeededRandom(seed: seed &+ 0x434F)
        let words = item.words.map(\.text)
        let blank = rng.below(max(words.count, 1))
        var visible = words
        if visible.indices.contains(blank) { visible[blank] = SentencePresentation.blankToken }
        let right = words.indices.contains(blank) ? words[blank] : ""
        var shown = SentencePresentation(kind: .complete, visibleWords: visible)
        shown.blankIndex = blank
        shown.choices = choices(right: right, seed: seed, language: language)
        return shown
    }

    /// The right word plus two misconception-tagged distractors drawn from the rest of the same bank.
    static func choices(right: String, seed: UInt64, language: Language) -> [SentenceChoice] {
        var rng = SeededRandom(seed: seed &+ 0x4348)
        var pool: [String] = []
        for item in bank(language) {
            for word in item.words where word.text.lowercased() != right.lowercased() {
                let text = word.text.lowercased()
                if !pool.contains(text) { pool.append(text) }
            }
        }
        let shuffledPool = rng.shuffled(pool)
        var texts = [right] + Array(shuffledPool.prefix(2))
        if texts.count < 3 { texts += Array(["le", "la"].prefix(3 - texts.count)) }
        let names = labels(language)
        var choices = texts.enumerated().map { index, text in
            SentenceChoice(text: text, misconception: index == 0 ? nil : names[(index - 1) % names.count])
        }
        choices = rng.shuffled(choices)
        return choices
    }

    static func scene(of item: SentenceItem, seed: UInt64, language: Language) -> SentencePresentation {
        var rng = SeededRandom(seed: seed &+ 0x5343)
        let lowered = item.words.map { $0.text.lowercased() }
        let table = alternatives(language)
        let pair = lowered.first { word in
            guard let alternative = table[word] else { return false }
            return !lowered.contains(alternative)
        }
        let right = pair ?? lowered.first ?? ""
        let other = pair.flatMap { table[$0] } ?? "autre"
        let objects = item.words.filter { !$0.isSight && $0.text.lowercased() != right }.map { $0.text.lowercased() }
        let correct = rng.below(2)
        let first = correct == 0 ? right : other
        let second = correct == 0 ? other : right
        var shown = SentencePresentation(kind: .scene, visibleWords: item.words.map(\.text))
        shown.scenes = [SceneRecipe(objects: objects, detail: first),
                        SceneRecipe(objects: objects, detail: second)]
        shown.correctSceneIndex = correct
        return shown
    }

    static func order(of item: SentenceItem, seed: UInt64) -> SentencePresentation {
        let words = item.words.map(\.text)
        var shown = SentencePresentation(kind: .order, visibleWords: words)
        shown.tiles = SentenceShuffle.shuffled(words, seed: seed)
        return shown
    }
}

/// One child's attempt at one sentence: the help ladder, Tap to Hear and the answer evidence.
public final class SentenceSession {
    public let item: SentenceItem
    public let presentation: SentencePresentation
    /// The language the child hears and reads; French by default.
    public let language: Language
    private let speech: any SpeechService
    /// The voice tag of the level's language: French or English.
    private var voiceTag: String { language == .fr ? "fr-FR" : "en-GB" }
    private let steps: [SentenceHelpStep]
    private var stepIndex = 0
    /// True once the child heard the whole sentence or the modelled phrase on tap.
    private var listened = false

    public init(item: SentenceItem, seed: UInt64, speech: any SpeechService, language: Language = .fr) {
        self.item = item
        self.language = language
        self.presentation = SentenceSelector.presentation(for: item, seed: seed, language: language)
        self.speech = speech
        let words = item.words.map(\.text)
        let split = words.count >= 3 ? 2 : 1
        let subject = Array(words.prefix(split))
        let rest = Array(words.dropFirst(split))
        self.steps = [.boundaries(words),
                      .phraseGroups(subject: subject, rest: rest),
                      .modelPhrase(rest.joined(separator: " "))]
    }

    /// The next help step, or nil once the ladder is used up. It never changes the answer or the stars.
    public func help() -> SentenceHelpStep? {
        guard stepIndex < steps.count else { return nil }
        stepIndex += 1
        return steps[stepIndex - 1]
    }

    /// Tap to Hear: one whole-sentence call per tap, never a call on its own.
    public func hearSentence() throws {
        listened = true
        _ = try speech.speak(voiceTag: voiceTag, text: item.sentence)
    }

    /// Step 3 on tap: speaks the modelled phrase only when the child asks for it.
    public func hearModelPhrase() throws {
        guard let last = steps.last, case let .modelPhrase(phrase) = last else { return }
        listened = true
        _ = try speech.speak(voiceTag: voiceTag, text: phrase)
    }

    /// Scores one choice; stars stay the same whatever help or listening came before.
    public func submit(choiceIndex: Int) -> SentenceAnswer {
        let choice = presentation.choices.indices.contains(choiceIndex) ? presentation.choices[choiceIndex] : nil
        let isCorrect = choice?.misconception == nil
        return SentenceAnswer(isCorrect: isCorrect, stars: 3,
                              countsAsIndependentDecoding: !listened,
                              misconception: isCorrect ? nil : choice?.misconception)
    }
}
