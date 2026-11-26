/// The four question kinds a French text asks.
public enum TextQuestionKind: String, Sendable, CaseIterable, Equatable {
    case evidence, order, pronoun, inference
}

/// One sentence of a text: its segmented words and the visible line the child reads.
public struct TextSentence: Sendable, Equatable {
    public var words: [SentenceWord]
    /// The visible sentence; words joined by one space.
    public var text: String { words.map(\.text).joined(separator: " ") }

    public init(_ words: [SentenceWord]) {
        self.words = words
    }
}

/// One question about a text: two choices, one answer, its kind and the sentence that proves it.
public struct TextQuestionItem: Sendable, Equatable {
    public let kind: TextQuestionKind
    public let prompt: String
    public var choices: [String]
    public let answerIndex: Int
    /// 0-based index of the sentence that carries the answer.
    public let evidenceSentence: Int
    /// Parallel to `choices`: the mistake each wrong choice stands for; nil only at the answer.
    public var misconceptions: [String?]

    public init(kind: TextQuestionKind, prompt: String, choices: [String], key: TextAnswerKey) {
        self.kind = kind
        self.prompt = prompt
        self.choices = choices
        self.answerIndex = key.answer
        self.evidenceSentence = key.evidence
        self.misconceptions = choices.indices.map { index in
            index == key.answer ? nil : "Ce n'est pas le mot du texte."
        }
    }
}

/// The answer index and the evidence sentence of one question.
public struct TextAnswerKey: Sendable, Equatable {
    public let answer: Int
    public let evidence: Int

    public init(answer: Int, evidence: Int) {
        self.answer = answer
        self.evidence = evidence
    }
}

/// One reading text of the R8 level: its sentences and its three questions.
public struct TextItem: Sendable, Equatable, Identifiable {
    public let id: String
    public var sentences: [TextSentence]
    public var questions: [TextQuestionItem]

    public init(id: String, sentences: [TextSentence], questions: [TextQuestionItem]) {
        self.id = id
        self.sentences = sentences
        self.questions = questions
    }
}

/// The French text bank of the R8 level: twelve texts and thirty-six questions.
public enum FrenchTextBank {
    /// Every grapheme the French rungs teach; a segmented word may use only these.
    static let taughtGraphemes: Set<String> = ["a", "e", "i", "o", "u", "m", "s", "f", "r", "l", "n",
                                               "t", "p", "d", "b", "ch", "ou"]
    /// The whole words a text may use instead of segmenting them.
    static let sightWords: Set<String> = ["le", "la", "les", "un", "une", "est", "et"]
    static let maximumSightShare = 0.45
    static let minimumSegmentedWords = 2

    static func word(_ text: String) -> SentenceWord {
        SentenceWord(text: text, graphemes: FrenchSentenceBank.graphemes(of: text), isSight: false)
    }

    static func sight(_ text: String) -> SentenceWord {
        SentenceWord(text: text, graphemes: [], isSight: true)
    }

    static func sentence(_ words: [SentenceWord]) -> TextSentence {
        TextSentence(words)
    }

    static func question(_ kind: TextQuestionKind, _ prompt: String, _ choices: [String],
                         _ answerThenEvidence: Int...) -> TextQuestionItem {
        let key = TextAnswerKey(answer: answerThenEvidence[0], evidence: answerThenEvidence[1])
        return TextQuestionItem(kind: kind, prompt: prompt, choices: choices, key: key)
    }

    public static let items: [TextItem] = [chat, poule, lune, renard, merle, champ,
                                           mer, salle, oiseau, maison, famille, nid]

    public static func item(id: String) -> TextItem? {
        items.first { $0.id == id }
    }

    // MARK: the twelve texts

    static let chat = TextItem(id: "fr-r8-01", sentences: [
        sentence([sight("Le"), word("chat"), word("dort"), word("sur"), sight("le"), word("tapis")]),
        sentence([sight("Le"), word("chien"), word("saute"), word("dans"), sight("le"), word("nid")])
    ], questions: [
        question(.evidence, "Qui dort sur le tapis ?", ["le chat", "le chien"], 0, 0),
        question(.order, "Où saute le chien ?", ["dans le nid", "sur le tapis"], 0, 1),
        question(.inference, "Qui saute ?", ["le chien", "le chat"], 0, 1)
    ])

    static let poule = TextItem(id: "fr-r8-02", sentences: [
        sentence([sight("La"), word("poule"), word("cherche"), word("dans"), sight("le"), word("sable")]),
        sentence([sight("Le"), word("poussin"), word("sort"), word("du"), word("nid")])
    ], questions: [
        question(.evidence, "Qui cherche dans le sable ?", ["la poule", "le poussin"], 0, 0),
        question(.evidence, "Qui sort du nid ?", ["le poussin", "la poule"], 0, 1),
        question(.pronoun, "Où cherche-t-elle ?", ["dans le sable", "du nid"], 0, 0)
    ])

    static let lune = TextItem(id: "fr-r8-03", sentences: [
        sentence([sight("La"), word("lune"), word("luit"), word("sur"), sight("le"), word("toit")]),
        sentence([sight("Le"), word("soleil"), word("luit"), word("dans"), sight("le"), word("matin")])
    ], questions: [
        question(.evidence, "Qui luit sur le toit ?", ["la lune", "le soleil"], 0, 0),
        question(.evidence, "Qui luit dans le matin ?", ["le soleil", "la lune"], 0, 1),
        question(.inference, "Que fait la lune ?", ["la lune luit", "le soleil luit"], 0, 0)
    ])

    static let renard = TextItem(id: "fr-r8-04", sentences: [
        sentence([sight("Le"), word("renard"), word("dort"), word("sous"), sight("le"), word("pommier")]),
        sentence([sight("La"), word("pomme"), word("tombe"), word("dans"), sight("le"), word("panier")])
    ], questions: [
        question(.evidence, "Qui dort sous le pommier ?", ["le renard", "la pomme"], 0, 0),
        question(.evidence, "Où tombe la pomme ?", ["dans le panier", "sous le pommier"], 0, 1),
        question(.pronoun, "Où dort-il ?", ["sous le pommier", "dans le panier"], 0, 0)
    ])

    static let merle = TextItem(id: "fr-r8-05", sentences: [
        sentence([sight("Le"), word("matin"), sight("le"), word("merle"), word("chante")]),
        sentence([sight("Le"), word("soir"), sight("le"), word("merle"), word("dort"), word("dans"), sight("le"),
                  word("nid")])
    ], questions: [
        question(.evidence, "Quand chante le merle ?", ["le matin", "le soir"], 0, 0),
        question(.evidence, "Où dort le merle ?", ["dans le nid", "le matin"], 0, 1),
        question(.order, "Que fait le merle le soir ?", ["le merle dort", "le merle chante"], 0, 1)
    ])

    static let champ = TextItem(id: "fr-r8-06", sentences: [
        sentence([sight("Le"), word("fermier"), word("marche"), word("dans"), sight("le"), word("champ")]),
        sentence([sight("Le"), word("fermier"), word("plante"), sight("le"), word("mais")])
    ], questions: [
        question(.evidence, "Qui marche dans le champ ?", ["le fermier", "le mais"], 0, 0),
        question(.evidence, "Que plante le fermier ?", ["le mais", "le fermier marche"], 0, 1),
        question(.order, "Le fermier marche. Puis ?", ["le fermier plante", "le fermier marche"], 0, 1)
    ])

    static let mer = TextItem(id: "fr-r8-07", sentences: [
        sentence([sight("Le"), word("bateau"), word("sort"), word("de"), sight("la"), word("mer")]),
        sentence([sight("Le"), word("poisson"), word("saute"), word("dans"), sight("la"), word("mer")])
    ], questions: [
        question(.inference, "Que fait le bateau ?", ["le bateau sort", "le poisson saute"], 0, 0),
        question(.evidence, "Qui saute dans la mer ?", ["le poisson", "le bateau"], 0, 1),
        question(.order, "Le bateau sort. Puis ?", ["le poisson saute", "le bateau sort"], 0, 1)
    ])

    static let salle = TextItem(id: "fr-r8-08", sentences: [
        sentence([sight("La"), word("salle"), word("a"), word("du"), word("soleil")]),
        sentence([sight("Les"), word("enfants"), word("dansent"), word("dans"), sight("la"), word("salle")])
    ], questions: [
        question(.evidence, "Qui danse dans la salle ?", ["les enfants", "du soleil"], 0, 1),
        question(.evidence, "Qu'y a-t-il dans la salle ?", ["du soleil", "les enfants"], 0, 0),
        question(.inference, "Que font les enfants ?", ["les enfants dansent", "du soleil"], 0, 1)
    ])

    static let oiseau = TextItem(id: "fr-r8-09", sentences: [
        sentence([sight("Le"), word("petit"), word("oiseau"), word("chante"), word("sur"), sight("la"),
                  word("branche")]),
        sentence([sight("Le"), word("chat"), word("dort"), word("sous"), sight("la"), word("branche")])
    ], questions: [
        question(.evidence, "Qui chante sur la branche ?", ["le petit oiseau", "le chat"], 0, 0),
        question(.evidence, "Qui dort sous la branche ?", ["le chat", "le petit oiseau"], 0, 1),
        question(.pronoun, "Où chante-t-il ?", ["sur la branche", "sous la branche"], 0, 0)
    ])

    static let maison = TextItem(id: "fr-r8-10", sentences: [
        sentence([sight("La"), word("maison"), word("a"), sight("un"), word("toit"), word("bleu")]),
        sentence([sight("Un"), word("chat"), word("dort"), word("sur"), sight("le"), word("toit")])
    ], questions: [
        question(.evidence, "Quelle est la couleur du toit ?", ["bleu", "un chat"], 0, 0),
        question(.evidence, "Qui dort sur le toit ?", ["un chat", "la maison"], 0, 1),
        question(.order, "Où dort le chat ?", ["sur le toit", "bleu"], 0, 1)
    ])

    static let famille = TextItem(id: "fr-r8-11", sentences: [
        sentence([word("Papa"), word("lit"), word("dans"), sight("la"), word("salle")]),
        sentence([word("Maman"), word("danse"), word("dans"), sight("la"), word("salle")])
    ], questions: [
        question(.evidence, "Qui lit dans la salle ?", ["papa", "maman"], 0, 0),
        question(.evidence, "Qui danse ?", ["maman", "papa"], 0, 1),
        question(.pronoun, "Que fait-il ?", ["papa lit", "maman danse"], 0, 0)
    ])

    static let nid = TextItem(id: "fr-r8-12", sentences: [
        sentence([sight("Un"), word("oiseau"), word("a"), sight("un"), word("nid"), word("dans"), sight("le"),
                  word("bois")]),
        sentence([sight("Le"), word("nid"), word("tombe"), word("sur"), sight("la"), word("table")])
    ], questions: [
        question(.evidence, "Où tombe le nid ?", ["sur la table", "dans le bois"], 0, 1),
        question(.evidence, "Qui a un nid ?", ["un oiseau", "la table"], 0, 0),
        question(.inference, "Où a-t-il son nid ?", ["dans le bois", "sur la table"], 0, 0)
    ])
}
