import Foundation

/// A drawn glyph: an SF Symbol, optionally with a diagonal slash drawn over it by the view.
public struct ChromeGlyph: Sendable, Equatable {
    public let symbolName: String
    public let slash: Bool
    /// Drawing scale of the symbol (1 = plain; the slashed note is one size larger).
    public let scale: Double
}

/// The make-10 icon: a ten-frame of rows x columns slots, the first `filledSlots` filled, the rest empty.
public struct TenFrameIconSpec: Sendable, Equatable {
    public let rows: Int
    public let columns: Int
    public let filledSlots: Int

    public var emptySlotIndices: [Int] { Array(filledSlots..<(rows * columns)) }
}

/// The diagonal slash over the music note when music is off (top-left to bottom-right).
public struct MusicSlashSpec: Sendable, Equatable {
    public let angleDegrees: Double
    public let strokeWidth: Double
    /// The slash extends past the note by this fraction of the glyph size on each end.
    public let overhang: Double
    /// Width of the background-colour knockout outline around the slash.
    public let knockoutWidth: Double
    /// Largest fraction of the stem's height the slash plus its outline may cover.
    public let stemClearance: Double
}

public struct BackGlyphSpec: Sendable, Equatable {
    public let symbolName: String
    public let pointSize: Double
    public let hitArea: Double
}

extension ChromeCatalog {
    static func iconKey(_ kind: ChromeIconKind) -> String {
        String(labelKey(kind).dropLast(".label".count))
    }

    /// The SF Symbol of a chrome icon kind (SF Symbols 5 names only).
    public static func symbolName(for kind: ChromeIconKind) -> String {
        switch kind {
        case .note, .noteSlashed: return TextTable.string("icon.music", .en)
        default: return TextTable.string(iconKey(kind), .en)
        }
    }

    public static var summaryBackSymbolName: String { TextTable.string("icon.summary.back", .en) }

    /// Music on is the plain note; off is the same note with a slash drawn over it.
    public static func music(on: Bool) -> ChromeGlyph {
        ChromeGlyph(symbolName: symbolName(for: .note), slash: !on,
                    scale: on ? plainGlyphScale : slashedGlyphScale)
    }

    public static let plainGlyphScale: Double = 1
    /// One size larger than the plain note, so the slashed note keeps its stem readable.
    public static let slashedGlyphScale: Double = 1.25

    /// Nominal point size of the note on the unit glyph box, to turn points into box fractions.
    static let glyphReferencePoints: Double = 24
    /// The stem's horizontal position on the unit glyph box (0 = left edge).
    static let stemCenterX: Double = 0.7

    /// True when the slash plus its outline covers more of the stem than the clearance allows.
    /// The covered stem length is the slash's total width measured along the vertical (width / sin angle).
    public static func musicSlashSpansStem(angleDegrees: Double, overhang: Double,
                                           strokeWidth: Double, knockoutWidth: Double) -> Bool {
        let radians = angleDegrees * Double.pi / 180
        let reach = (0.5 + overhang) * abs(cos(radians))
        guard reach >= abs(stemCenterX - 0.5) else { return false }
        let total = strokeWidth + 2 * knockoutWidth
        let covered = total / glyphReferencePoints / abs(sin(radians))
        return covered > musicSlash.stemClearance
    }

    public static let tenFrameIcon = TenFrameIconSpec(rows: 2, columns: 5, filledSlots: 9)

    public static let musicSlash = MusicSlashSpec(angleDegrees: 45, strokeWidth: 2,
                                                  overhang: 0.2, knockoutWidth: 1,
                                                  stemClearance: 0.3)

    public static let roundBack = BackGlyphSpec(symbolName: "arrow.left.circle.fill", pointSize: 44,
                                                hitArea: ChromeIcon.minimumTarget)

    public static let brandSymbolName = "leaf.fill"
    public static let lockedSymbolName = "lock.fill"
    public static let reviewSymbolName = "mappin.and.ellipse"
    public static let suggestedSymbolName = "star.fill"
    /// One symbol per help-ladder step: cue, partial worked example, one-move demonstration.
    public static let helpSymbolNames = ["circle", "circle.fill", "figure.walk"]

    /// Symbol of a trail tile: check when completed, play when open, lock when locked.
    public static func levelStateSymbolName(isCompleted: Bool, isUnlocked: Bool) -> String {
        if isCompleted { return symbolName(for: .check) }
        return isUnlocked ? symbolName(for: .play) : lockedSymbolName
    }

    /// Symbol drawn for an activity identity icon (question and level tile).
    public static func activitySymbolName(_ kind: ActivityIconKind) -> String {
        switch kind {
        case .dotCluster: return TextTable.string("icon.counting", .en)
        case .tenFrameGap: return TextTable.string("icon.bond", .en)
        case .joiningGroups: return "plus.circle.fill"
        case .crossedOut: return "minus.circle.fill"
        case .repeatedShapes: return "ellipsis.circle.fill"
        case .differentRows: return "arrow.left.arrow.right"
        case .soundWave: return "waveform"
        case .syllableBlocks: return "puzzlepiece.fill"
        case .wordCard: return "text.book.closed.fill"
        case .orderedTiles: return "signpost.right.fill"
        case .blendedSounds: return "map.fill"
        case .swappedLetter: return "textformat"
        case .letterPair: return "character.book.closed.fill"
        case .joinedWord: return "book.fill"
        case .mendedWord: return "hand.tap.fill"
        case .countedRow: return "123.rectangle"
        case .tenFrameSplit: return "rectangle.split.2x1"
        case .bridgeDownStep: return "arrow.turn.down.right"
        case .stackedTens: return "square.stack.3d.up"
        case .sentenceLine: return "flag.fill"
        case .englishSentenceLine: return "flag"
        case .textLines: return "signpost.right"
        case .englishTextLines: return "number.circle"
        }
    }

    /// The nature-journal book, from the icon table.
    public static var journalSymbolName: String { TextTable.string("icon.journal", .en) }

    /// Terrarium-only symbols outside the chrome list: the welcome hand (a real SF Symbols 2 name).
    /// Also holds the robot-c4 repeat block symbol (`icon.repeat`), which the chrome list does not use.
    public static let terrariumSymbolNames = ["hand.raised.fill", "repeat"]

    /// Every SF Symbol name the views may draw; the single list.
    public static var allSymbolNames: [String] {
        let kinds: [ChromeIconKind] = [.flag(.fr), .flag(.gb), .note, .play, .trail, .math, .ear, .back, .check, .star]
        let names = kinds.map { symbolName(for: $0) }
            + [summaryBackSymbolName, roundBack.symbolName, brandSymbolName, lockedSymbolName,
                                                reviewSymbolName, suggestedSymbolName, journalSymbolName] + helpSymbolNames
            + ActivityIdentity.all.map { activitySymbolName($0.iconKind) }
            + ["link"]
            + MusicNote.allCases.map(\.symbolName) + MusicBeat.allCases.map(\.symbolName)
        var seen = Set<String>()
        return names.filter { seen.insert($0).inserted }
    }
}

/// The top-bar star button: icon-led, at least 56 pt, opens the terrarium, carries the ring as text.
public struct StarButton: Sendable, Equatable {
    public let identifier: String
    public let kind: ChromeIconKind
    public let minSide: Double
    public let label: String
    public let ringText: String
    public let silhouette: RingSilhouette
    public let ringFraction: Double
    public let showsBadge: Bool
    public let missingCountText: String?
}

public enum ChromePresentation {
    /// The same button on every screen.
    public static func starButton(for screen: Screen, record: ProgressRecord, language: Language) -> StarButton {
        let ring = RingProgress(record)
        let ringText = ring.text(language)
        let base = TextTable.string("chrome.terrarium.label", language)
        return StarButton(identifier: SproutIdentifier.terrariumOpen, kind: .star,
                          minSide: ChromeIcon.minimumTarget, label: base + ", " + ringText,
                          ringText: ringText, silhouette: ring.silhouette,
                          ringFraction: ring.fraction, showsBadge: false, missingCountText: nil)
    }
}

/// What the terrarium sheet shows: the terrarium itself; the ring text is only its accessibility label.
public enum TerrariumSheetContent {
    case terrarium(TerrariumViewModel)
    case ringText(String)
}

extension ChromePresentation {
    /// Side of the sheet's close control, in points (at least 44).
    public static let terrariumCloseSide: Double = 56
    public static let terrariumCloseLabelKey = "terrarium.close.label"

    /// The terrarium of the current save.
    @MainActor
    public static func terrariumSheetContent(store: any ProgressStore, clock: any ClockService,
                                             speech: any SpeechService, language: Language) -> TerrariumSheetContent {
        .terrarium(TerrariumViewModel(store: store, clock: clock, speech: speech, language: language))
    }

    /// The sheet's accessibility label: the ring text ("3 of 5 stars").
    public static func terrariumSheetAccessibilityLabel(record: ProgressRecord, language: Language) -> String {
        RingProgress(record).text(language)
    }
}

public enum SelectionMarker: Sendable, Equatable {
    case none, check, underline
}

public struct LanguageSegment: Sendable, Equatable {
    public let code: String
    public let flag: ChromeFlag
    public let accessibilityLabel: String
    public let isSelected: Bool
    public let marker: SelectionMarker
}

extension LanguageControl {
    /// Both languages, FR then EN; the current one is selected and marked beyond colour.
    public static func segments(current: Language) -> [LanguageSegment] {
        [Language.fr, Language.en].map { language in
            let selected = language == current
            return LanguageSegment(
                code: language.rawValue.uppercased(),
                flag: language == .fr ? .fr : .gb,
                accessibilityLabel: TextTable.string("settings.language." + language.rawValue, current),
                isSelected: selected,
                marker: selected ? .underline : .none)
        }
    }
}

public enum TypeSizeCategory: Sendable, CaseIterable {
    case xSmall, small, medium, large, xLarge, xxLarge, xxxLarge
    case accessibility1, accessibility2, accessibility3, accessibility4, accessibility5

    public var isAccessibilitySize: Bool {
        switch self {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5: return true
        default: return false
        }
    }
}

public enum TopBarMode: Sendable, Equatable {
    case full, compact

    public var showsTitleText: Bool { self == .full }
    public var showsIcon: Bool { true }
    public var iconKeepsLabel: Bool { true }
    public var languageLineLimit: Int { 1 }
}

public enum TopBarLayout {
    /// Narrowest supported screen (iPhone SE) is 320 pt; the compact bar must fit it.
    public static let minimumWidth: Double = 320

    public static func mode(for size: TypeSizeCategory) -> TopBarMode {
        size.isAccessibilitySize ? .compact : .full
    }

    /// Every bar variant (full title, icon-only) uses the same interaction.
    public static func titleInteraction(mode: TopBarMode, language: Language) -> TitleInteraction {
        ChromeCatalog.titleInteraction(language: language)
    }
}

/// Accessibility identifiers shared by the views and the UI automation.
public enum SproutIdentifier {
    public static let title = "sproutlab.title"
    public static let icon = "sproutlab.icon"
    public static let back = "sproutlab.back"
    public static let music = "sproutlab.music"
    public static let language = "sproutlab.language"
    public static let listen = "sproutlab.listen"
    public static let stimulus = "sproutlab.stimulus"
    public static let terrariumOpen = "sproutlab.terrarium.open"
    public static let terrariumView = "sproutlab.terrarium.view"

    public static func choice(_ index: Int) -> String { "sproutlab.choice.\(index)" }
    public static func level(_ id: String) -> String { "sproutlab.level.\(id)" }

    public static func all(levelIds: [String]) -> [String] {
        [title, icon, back, music, language, listen] + (0..<3).map { choice($0) }
            + [stimulus] + levelIds.map { level($0) }
    }
}
