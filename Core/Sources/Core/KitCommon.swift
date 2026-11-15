/// Shared values of the interaction kit: sizes, commands, accessibility actions, tap targets, announcements.
public enum KitMetrics {
    /// Smallest side, in points, of any kit tap target.
    public static let minTarget: Double = 56
    /// Wider side for syllable tiles.
    public static let wideTarget: Double = 80
}

public enum KitCommand: Sendable, Equatable {
    case select(String)
    case place(Int)
    case tapFilled(Int)
    case undo
    case moveEarlier(String)
    case moveLater(String)
    case tapBin(Int)
    case tapSorted(String)
    case beginAnswering
    case submit(String)
    case reveal
    case reset
}

/// One VoiceOver / Switch Control action: a localised label key plus the command a tap would send.
public struct KitAccessibilityAction: Sendable, Equatable {
    public let labelKey: String
    public let command: KitCommand
    /// Token the label is about (spoken after the label); nil when the label stands alone.
    public let subject: String?

    public init(labelKey: String, command: KitCommand, subject: String? = nil) {
        self.labelKey = labelKey
        self.command = command
        self.subject = subject
    }
}

public struct KitTapTarget: Sendable, Equatable {
    public let identifier: String
    public let command: KitCommand
    public let subject: String?
    public let width: Double
    public let height: Double

    public init(identifier: String, command: KitCommand, subject: String? = nil,
                size: (width: Double, height: Double) = (KitMetrics.minTarget, KitMetrics.minTarget)) {
        self.identifier = identifier
        self.command = command
        self.subject = subject
        self.width = max(size.width, KitMetrics.minTarget)
        self.height = max(size.height, KitMetrics.minTarget)
    }
}

public struct KitAnnouncement: Sendable, Equatable {
    public let key: String
    public let subject: String?

    public init(key: String, subject: String? = nil) {
        self.key = key
        self.subject = subject
    }
}

public enum KitIdentifier {
    public static let prefix = "sproutlab.kit."

    public static func make(_ part: String, _ index: Int? = nil) -> String {
        index.map { prefix + part + "." + String($0) } ?? prefix + part
    }
}

/// A component whose accessibility actions run the same code path as its taps.
public protocol KitComponent: Sendable, Equatable {
    mutating func apply(_ command: KitCommand)
    var accessibilityActions: [KitAccessibilityAction] { get }
    var tapTargets: [KitTapTarget] { get }
    var announcements: [KitAnnouncement] { get }
}

public extension KitComponent {
    mutating func perform(_ action: KitAccessibilityAction) { apply(action.command) }
}

public enum KitError: Error, Equatable {
    case tokenCount(Int)
    case binCount(Int)
    case unknownIcon(String)
}

extension TextTable {
    static let kitTexts: [String: TextEntry] = [
        "kit.action.select": TextEntry("Choisir", "Pick"),
        "kit.action.place": TextEntry("Placer ici", "Place here"),
        "kit.action.return": TextEntry("Reprendre", "Take back"),
        "kit.action.undo": TextEntry("Annuler", "Undo"),
        "kit.action.earlier": TextEntry("Déplacer plus tôt", "Move earlier"),
        "kit.action.later": TextEntry("Déplacer plus tard", "Move later"),
        "kit.action.bin": TextEntry("Ranger dans la boîte", "Put in this bin"),
        "kit.action.sorted": TextEntry("Reprendre du rangement", "Take out of the bin"),
        "kit.action.begin": TextEntry("Répondre", "Answer"),
        "kit.action.submit": TextEntry("Valider la réponse", "Submit answer"),
        "kit.action.reveal": TextEntry("Montrer l'image", "Show the picture"),
        "kit.action.reset": TextEntry("Recommencer", "Start again"),
        "kit.bin.label": TextEntry("Ranger ici : {what}", "Put here: {what}"),
        "kit.bin.uses.what": TextEntry("les sons du mot", "the sounds in the word"),
        "kit.bin.avoids.what": TextEntry("les sons qui ne sont pas dans le mot", "the sounds not in the word"),
        "kit.bin.fallback": TextEntry("Boîte", "Bin"),
        "kit.say.selected": TextEntry("Choisi", "Picked"),
        "kit.say.placed": TextEntry("Placé", "Placed"),
        "kit.say.returned": TextEntry("Repris", "Taken back"),
        "kit.say.undone": TextEntry("Annulé", "Undone"),
        "kit.say.moved": TextEntry("Déplacé", "Moved"),
        "kit.say.sorted": TextEntry("Rangé", "Sorted"),
        "kit.say.answering": TextEntry("À toi de répondre", "Your turn to answer"),
        "kit.say.revealed": TextEntry("Voici l'image", "Here is the picture"),
        "kit.say.reset": TextEntry("On recommence", "Starting again"),
        "kit.say.complete": TextEntry("Terminé", "All done")
    ]
}
