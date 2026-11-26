extension ContentLint {
    /// The decodability and shape check of the French text bank: an empty result means the bank passes.
    public static func frenchTextFindings(_ texts: [TextItem]) -> [ContentFinding] {
        var findings: [ContentFinding] = []
        for text in texts {
            findings += textFindings(text)
        }
        return findings
    }

    static func textFindings(_ text: TextItem) -> [ContentFinding] {
        var findings: [ContentFinding] = []
        if !(2...5).contains(text.sentences.count) {
            findings.append(ContentFinding(kind: "french-text-length", subject: text.id))
        }
        if text.questions.count != 3 {
            findings.append(ContentFinding(kind: "french-text-questions", subject: text.id))
        }
        if !text.questions.contains(where: { $0.kind == .evidence }) {
            findings.append(ContentFinding(kind: "french-text-evidence", subject: text.id))
        }
        for sentence in text.sentences {
            findings += sentenceFindings(sentence, id: text.id)
        }
        for question in text.questions {
            findings += questionFindings(question, text: text)
        }
        return findings
    }

    static func sentenceFindings(_ sentence: TextSentence, id: String) -> [ContentFinding] {
        var findings: [ContentFinding] = []
        if sentence.words.count < 2 {
            findings.append(ContentFinding(kind: "french-text-sentence", subject: id))
        }
        let sight = sentence.words.filter(\.isSight).count
        if Double(sight) > FrenchTextBank.maximumSightShare * Double(sentence.words.count) {
            findings.append(ContentFinding(kind: "french-text-sight-share", subject: id))
        }
        if sentence.words.count - sight < FrenchTextBank.minimumSegmentedWords {
            findings.append(ContentFinding(kind: "french-text-segmented", subject: id))
        }
        for word in sentence.words {
            findings += wordFindings(word, id: id)
        }
        return findings
    }

    static func wordFindings(_ word: SentenceWord, id: String) -> [ContentFinding] {
        if word.isSight {
            let listed = FrenchTextBank.sightWords.contains(word.text.lowercased())
            return listed ? [] : [ContentFinding(kind: "french-text-sight-word", subject: id + ":" + word.text)]
        }
        if word.graphemes.isEmpty {
            return [ContentFinding(kind: "french-text-graphemes", subject: id + ":" + word.text)]
        }
        var findings: [ContentFinding] = []
        for token in word.graphemes {
            if token.hasPrefix("~") {
                let letter = String(token.dropFirst()).lowercased()
                if !["e", "s", "t"].contains(letter) {
                    findings.append(ContentFinding(kind: "french-text-silent", subject: id + ":" + token))
                }
            } else if !FrenchTextBank.taughtGraphemes.contains(token.lowercased()) {
                findings.append(ContentFinding(kind: "french-text-untaught", subject: id + ":" + token))
            }
        }
        let joined = word.graphemes.map { $0.replacingOccurrences(of: "~", with: "") }
            .joined().lowercased()
        if joined != word.text.lowercased() {
            findings.append(ContentFinding(kind: "french-text-spelling", subject: id + ":" + word.text))
        }
        return findings
    }

    static func questionFindings(_ question: TextQuestionItem, text: TextItem) -> [ContentFinding] {
        var findings: [ContentFinding] = []
        let id = text.id
        if question.choices.count != 2 || question.choices.contains(where: \.isEmpty) {
            findings.append(ContentFinding(kind: "french-text-choices", subject: id))
        }
        if !question.choices.indices.contains(question.answerIndex) {
            findings.append(ContentFinding(kind: "french-text-answer", subject: id))
        }
        if !text.sentences.indices.contains(question.evidenceSentence) {
            findings.append(ContentFinding(kind: "french-text-evidence-index", subject: id))
        }
        if question.prompt.isEmpty {
            findings.append(ContentFinding(kind: "french-text-prompt", subject: id))
        }
        if question.misconceptions.count != question.choices.count {
            findings.append(ContentFinding(kind: "french-text-misconception", subject: id))
        }
        return findings
    }
}
