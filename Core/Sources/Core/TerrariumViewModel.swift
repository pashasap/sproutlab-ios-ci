import Foundation
import Observation

@MainActor
@Observable
public final class TerrariumViewModel {
    public var language: Language
    public var reduceMotion = false
    public let scene = GardenScene.garden
    public let habitats: [TerrariumHabitat]
    public let accessibilityId = "sproutlab.terrarium"
    /// The two-phase dial: day or night; a tap toggles.
    public private(set) var dialPhase: DayPhase = .day
    public let backControl = TerrariumControl(accessibilityId: "sproutlab.terrarium.back",
                                              iconKey: "icon.back", labelKey: "icon.back.label", side: 56)
    /// The sheet's close control: the back glyph with the close label.
    public let closeControl = TerrariumControl(accessibilityId: "sproutlab.terrarium.close",
                                               iconKey: "icon.back", labelKey: "terrarium.close.label",
                                               side: ChromePresentation.terrariumCloseSide)
    /// The book icon that opens the nature journal.
    public let journalControl = TerrariumControl(accessibilityId: "sproutlab.journal",
                                                 iconKey: "icon.journal", labelKey: "icon.journal.label", side: 56)
    public var panRange: ClosedRange<Double> { 0...scene.maxPanOffset }
    /// Fixed near the top of the screen; panning never moves it.
    public let backPosition = GardenPoint(x: 44, y: 48)
    public private(set) var panOffset: Double = 0
    public let panStep: Double

    private let collection: CollectionViewModel
    private let speech: any SpeechService
    private var tappedId: String?
    /// Plays a met resident's motif on a tap; silent until the app supplies a real service.
    @ObservationIgnored public var audio: any AudioService = SilentAudio()

    public init(store: any ProgressStore, clock: any ClockService, speech: any SpeechService, language: Language) {
        self.collection = CollectionViewModel(store: store, clock: clock)
        self.speech = speech
        self.language = language
        self.panStep = GardenScene.garden.screenWidth / 2
        self.habitats = Self.habitatRows()
    }

    private static func habitatRows() -> [TerrariumHabitat] {
        var order: [String] = []
        for item in Collectible.table where !order.contains(item.habitatId) { order.append(item.habitatId) }
        return order.map { id in
            TerrariumHabitat(id: id, accessibilityId: "sproutlab.habitat." + id,
                             residentIds: Collectible.table.filter { $0.habitatId == id }.map(\.id))
        }
    }

    // MARK: pan

    public func panRight() { panOffset = min(panOffset + panStep, scene.maxPanOffset) }
    public func panLeft() { panOffset = max(panOffset - panStep, 0) }

    // MARK: dial and poses

    public func toggleDial() { dialPhase = dialPhase == .day ? .night : .day }

    public var dialAccessibilityValue: String { SunMoonDial.accessibilityValue(dialPhase, language) }

    /// A met or ready-arrived resident's pose for a phase; nil while not arrived.
    public func residentPose(_ id: String, phase: DayPhase) -> ResidentPoseKind? {
        guard collection.state(of: id) != .notArrived else { return nil }
        return ResidentPoseKind.pose(id, phase)
    }

    public func residentPose(_ id: String) -> ResidentPoseKind? { residentPose(id, phase: dialPhase) }

    // MARK: residents

    public var residents: [TerrariumResident] {
        habitats.flatMap(\.residentIds).compactMap { resident($0) }
    }

    public func resident(_ id: String) -> TerrariumResident? {
        guard let item = Collectible.find(id) else { return nil }
        let state = collection.state(of: id)
        let spot = scene.spots[id] ?? GardenPoint(x: scene.width / 2, y: scene.height / 2)
        let posed = state == .met && tappedId == id
        return TerrariumResident(
            id: id, accessibilityId: "sproutlab.creature." + id, state: state, position: spot,
            tapArea: scene.tapArea(around: spot, side: 64),
            isSilhouette: state == .notArrived,
            placeholder: state == .notArrived ? Recipe.table.first { $0.id == id }?.placeholder : nil,
            milestoneStars: state == .notArrived ? item.milestone : nil,
            welcome: state == .ready ? welcomeControl(id) : nil,
            wobble: wobble(for: state, item), tapPose: posed,
            bubble: posed ? bubble(for: item) : nil,
            accessibilityLabel: label(for: item, state: state))
    }

    private func welcomeControl(_ id: String) -> TerrariumControl {
        TerrariumControl(accessibilityId: "sproutlab.welcome." + id, iconKey: "icon.hand",
                         labelKey: "icon.hand.label", side: 56)
    }

    /// Ready residents wobble, except rooted star-plants (fern, glowing mushroom), which stay still.
    private func wobble(for state: CollectibleState, _ item: Collectible) -> WobbleMode {
        let rooted = item.rule != .free && Recipe.table.first { $0.id == item.id }?.placeholder == .seed
        guard state == .ready, !rooted else { return .none }
        return reduceMotion ? .staticTilt : .animated
    }

    private func spokenName(_ item: Collectible) -> String {
        let name = language == .fr ? item.nameFR.lowercased() : item.nameEN.lowercased()
        guard language == .fr else { return name }
        return item.article.hasSuffix("'") ? item.article + name : item.article + " " + name
    }

    private func bubble(for item: Collectible) -> NameBubble {
        NameBubble(iconKey: "icon.hear", text: spokenName(item),
                   ear: TerrariumControl(accessibilityId: "sproutlab.ear." + item.id,
                                         iconKey: "icon.hear", labelKey: "icon.hear.label", side: 56))
    }

    private func label(for item: Collectible, state: CollectibleState) -> String {
        var text = item.name(language) + ", " + TextTable.string("terrarium.state." + String(describing: state), language)
        if state == .notArrived {
            text += ", " + TextTable.string("terrarium.milestone", language)
                .replacingOccurrences(of: "{n}", with: String(item.milestone))
        }
        return text
    }

    // MARK: actions

    /// Welcomes a ready resident; never touches the stars.
    @discardableResult
    public func welcome(_ id: String) -> Bool {
        collection.welcome(id)
    }

    /// Only a met resident reacts; tapping never speaks.
    public func tap(_ id: String) {
        guard collection.state(of: id) == .met else { return }
        tappedId = id
        collection.recordStamp(.heard, for: id)
        if let motif = ResidentCalls.recipes[id] { audio.play(motif, on: .effects) }
    }

    // MARK: journal

    /// The journal of the current save.
    public var journalScreen: JournalScreen { JournalScreen(record: collection.record, language: language) }

    /// Opening the journal only reads the save; it plays nothing and changes nothing.
    public func openJournal() {}

    /// Night view: every met resident that is awake at night gets the night stamp.
    public func viewGardenAtNight() {
        for item in Collectible.table where SkyPalette.awakeSet(.night).contains(item.id) {
            collection.recordStamp(.seenAtNight, for: item.id)
        }
    }

    public func countResident(_ id: String) { collection.recordStamp(.counted, for: id) }

    public func feedResident(_ id: String) { collection.recordStamp(.fed, for: id) }

    /// The ear button: the only path that speaks.
    public func speakName(_ id: String) {
        guard let item = Collectible.find(id), collection.state(of: id) == .met else { return }
        let tag = language == .fr ? "fr-FR" : "en-US"
        _ = try? speech.speak(voiceTag: tag, text: spokenName(item))
    }

    public func acknowledgement(of id: String) -> String? {
        guard let item = Collectible.find(id), collection.state(of: id) == .met else { return nil }
        return TextTable.string("terrarium.ack", language)
            .replacingOccurrences(of: "{name}", with: spokenName(item))
    }
}
