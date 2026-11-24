/// The authored English reading bank for EN1, EN2 and EN3. Every item is written in English for a Grade 1
/// early reader; none is translated from the French bank, and none shares an id with it.
public enum ReadingENBank {
    public static let levelIdPrefix = "reading-en-"

    /// True for the three readingEN level ids; their progress lives in the readingEN section.
    public static func owns(levelId: String) -> Bool { levelId.hasPrefix(levelIdPrefix) }

    public static func items(rung: ReadingENRung) -> [ReadingENItem] {
        switch rung {
        case .en1: return en1Items
        case .en2: return en2Items
        case .en3: return en3Items
        }
    }

    public static let allItems: [ReadingENItem] = ReadingENRung.allCases.flatMap { items(rung: $0) }

    private static let byId: [String: ReadingENItem] = Dictionary(
        allItems.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    public static func item(id: String) -> ReadingENItem? { byId[id] }

    // MARK: sounds

    private static let letterSounds: [String: String] = [
        "a": "/a/", "e": "/e/", "i": "/i/", "o": "/o/", "u": "/u/", "b": "/b/", "c": "/k/", "d": "/d/",
        "f": "/f/", "g": "/g/", "h": "/h/", "j": "/j/", "k": "/k/", "l": "/l/", "m": "/m/", "n": "/n/",
        "p": "/p/", "r": "/r/", "s": "/s/", "t": "/t/", "w": "/w/", "x": "/ks/"
    ]

    static func sound(_ letter: String) -> String { letterSounds[letter] ?? "/" + letter + "/" }

    private static func letters(_ word: String) -> [String] { word.map(String.init) }

    // MARK: EN1

    private static let singleLetters = ["a", "e", "i", "o", "u", "b", "d", "f", "g", "h", "j", "k", "l", "m",
                                        "n", "p", "r", "s", "t"]
    private static let sequenceWords = ["cat", "dog", "pig", "sun", "hen", "bus", "cup", "hat", "bed", "pin",
                                        "log", "net", "fox", "map", "sit", "hot", "run", "leg"]

    private static let en1Items: [ReadingENItem] = {
        let singles = singleLetters.map {
            ReadingENItem(id: "en1-sound-" + $0, rung: .en1, activity: .graphemeSound).sounds([$0], [sound($0)])
        }
        let sequences = sequenceWords.map { word in
            ReadingENItem(id: "en1-cvc-" + word, rung: .en1, activity: .cvcSequence)
                .sounds(letters(word), letters(word).map(sound)).spelling([word])
        }
        return singles + sequences
    }()

    // MARK: EN2

    static let revealWords = ["cat", "hen", "pig", "dog", "sun", "bus", "cup", "hat", "bed", "pin", "log", "net"]
    private static let changePairs = [("cat", "cot"), ("hat", "hit"), ("pig", "peg"), ("pin", "pen"),
                                      ("bed", "bad"), ("net", "nut"), ("dog", "dig"), ("log", "leg"),
                                      ("sun", "fun"), ("bus", "bug"), ("cup", "cap"), ("hen", "ten")]
    /// Every build round shows a picture of its word, so it never relies on audio alone.
    private static let buildWords = revealWords

    private static func tiles(for word: String) -> [String] {
        let spare = ["x", "z", "q", "v"].first { !word.contains($0) } ?? "x"
        return (letters(word) + [spare]).sorted()
    }

    private static let en2Items: [ReadingENItem] = {
        let reveals = revealWords.map {
            ReadingENItem(id: "en2-read-" + $0, rung: .en2, activity: .readReveal)
                .spelling([$0]).pictured("en-" + $0)
        }
        let changes = changePairs.map {
            ReadingENItem(id: "en2-change-\($0.0)-\($0.1)", rung: .en2, activity: .changeGrapheme)
                .spelling([$0.0, $0.1])
        }
        let builds = buildWords.map {
            ReadingENItem(id: "en2-build-" + $0, rung: .en2, activity: .buildTiles)
                .spelling([$0], tiles: tiles(for: $0)).pictured("en-" + $0)
        }
        return reveals + changes + builds
    }()

    // MARK: EN3

    private static let digraphSounds = ["sh": "/sh/", "ch": "/ch/", "th": "/th/"]
    private static let digraphWords: [(String, [String])] = [
        ("sh", ["ship", "shop", "fish", "dish", "shed", "shut", "wish"]),
        ("ch", ["chip", "chop", "chin", "much", "such", "chum", "rich"]),
        ("th", ["thin", "this", "that", "bath", "then", "with", "path"])
    ]
    private static let blendWords = ["frog", "drum", "stop", "flag", "crab", "grin", "plan", "skip", "step",
                                     "swim", "snap", "clap"]
    private static let repairs = [("sh", "s hip", "ship"), ("sh", "fis h", "fish"), ("sh", "s hop", "shop"),
                                  ("ch", "c hip", "chip"), ("ch", "mu c h", "much"), ("ch", "c hin", "chin"),
                                  ("th", "t hin", "thin"), ("th", "wit h", "with"), ("th", "t hat", "that")]

    private static let en3Items: [ReadingENItem] = {
        var out: [ReadingENItem] = []
        for (digraph, words) in digraphWords {
            out += words.map {
                ReadingENItem(id: "en3-digraph-" + $0, rung: .en3, activity: .digraph)
                    .sounds([digraph], [digraphSounds[digraph] ?? ""]).spelling([$0])
            }
        }
        out += blendWords.map {
            ReadingENItem(id: "en3-blend-" + $0, rung: .en3, activity: .blend)
                .sounds(letters($0), letters($0).map(sound)).spelling([$0])
        }
        out += repairs.map {
            ReadingENItem(id: "en3-split-" + $0.2, rung: .en3, activity: .repairSplit)
                .sounds([$0.0], [digraphSounds[$0.0] ?? ""]).spelling([$0.1, $0.2])
        }
        return out
    }()
}
