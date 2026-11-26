extension ContentLint {
    /// The decodability and shape check of the English text bank: an empty result means the bank passes.
    public static func englishTextFindings(_ texts: [TextItem]) -> [ContentFinding] {
        var findings: [ContentFinding] = []
        for text in texts {
            findings += englishTextFindings(text)
        }
        return findings
    }

    static func englishTextFindings(_ text: TextItem) -> [ContentFinding] {
        var findings: [ContentFinding] = []
        if !(2...5).contains(text.sentences.count) {
            findings.append(ContentFinding(kind: "english-text-length", subject: text.id))
        }
        if text.questions.count != 3 {
            findings.append(ContentFinding(kind: "english-text-questions", subject: text.id))
        }
        if !text.questions.contains(where: { $0.kind == .evidence }) {
            findings.append(ContentFinding(kind: "english-text-evidence", subject: text.id))
        }
        for sentence in text.sentences {
            findings += englishSentenceFindings(sentence, id: text.id)
        }
        for question in text.questions {
            findings += englishQuestionFindings(question, text: text)
        }
        return findings
    }

    static func englishSentenceFindings(_ sentence: TextSentence, id: String) -> [ContentFinding] {
        var findings: [ContentFinding] = []
        if sentence.words.count < 2 {
            findings.append(ContentFinding(kind: "english-text-sentence", subject: id))
        }
        let sight = sentence.words.filter(\.isSight).count
        if Double(sight) > EnglishTextBank.maximumSightShare * Double(sentence.words.count) {
            findings.append(ContentFinding(kind: "english-text-sight-share", subject: id))
        }
        if sentence.words.count - sight < EnglishTextBank.minimumSegmentedWords {
            findings.append(ContentFinding(kind: "english-text-segmented", subject: id))
        }
        for word in sentence.words {
            findings += englishWordFindings(word, id: id)
        }
        return findings
    }

    static func englishWordFindings(_ word: SentenceWord, id: String) -> [ContentFinding] {
        if word.isSight {
            let listed = EnglishTextBank.sightWords.contains(word.text.lowercased())
            return listed ? [] : [ContentFinding(kind: "english-text-sight-word", subject: id + ":" + word.text)]
        }
        if word.graphemes.isEmpty {
            return [ContentFinding(kind: "english-text-graphemes", subject: id + ":" + word.text)]
        }
        var findings: [ContentFinding] = []
        for token in word.graphemes where !EnglishTextBank.taughtGraphemes.contains(token.lowercased()) {
            findings.append(ContentFinding(kind: "english-text-untaught", subject: id + ":" + token))
        }
        if word.graphemes.joined().lowercased() != word.text.lowercased() {
            findings.append(ContentFinding(kind: "english-text-spelling", subject: id + ":" + word.text))
        }
        return findings
    }

    static func englishQuestionFindings(_ question: TextQuestionItem, text: TextItem) -> [ContentFinding] {
        var findings: [ContentFinding] = []
        let id = text.id
        if question.choices.count != 2 || question.choices.contains(where: \.isEmpty) {
            findings.append(ContentFinding(kind: "english-text-choices", subject: id))
        }
        if !question.choices.indices.contains(question.answerIndex) {
            findings.append(ContentFinding(kind: "english-text-answer", subject: id))
        }
        if !text.sentences.indices.contains(question.evidenceSentence) {
            findings.append(ContentFinding(kind: "english-text-evidence-index", subject: id))
        }
        if question.prompt.isEmpty {
            findings.append(ContentFinding(kind: "english-text-prompt", subject: id))
        }
        if question.misconceptions.count != question.choices.count {
            findings.append(ContentFinding(kind: "english-text-misconception", subject: id))
        }
        return findings
    }
}
