import Foundation
import Observation

public enum Screen: Equatable, Sendable {
    case welcome
    case trail
    case round
    case summary
}

@MainActor
@Observable
public final class AppViewModel {
    public private(set) var screen: Screen = .welcome {
        didSet { if screen != oldValue { services.audio.screenChanged() } }
    }
    public private(set) var language: Language
    public private(set) var totalStars: Int
    public private(set) var completedLevels: [String]
    public private(set) var round: RoundViewModel?
    public private(set) var musicOn: Bool
    /// A TextTable key for a non-blocking message, nil when none.
    public private(set) var notice: String?
    /// The most recent save result, nil before any save.
    public private(set) var lastSave: SaveReport?
    public private(set) var diagnosticsVisible = false
    public private(set) var terrariumVisible = false
    public let trail: TrailViewModel

    private var record: ProgressRecord
    private var musicStarted = false
    /// The round whose result is already committed; guards against a second commit.
    private var committedRound: RoundViewModel?
    private let store: any ProgressStore
    private let services: Services

    public init(store: any ProgressStore, services: Services,
                curriculum: [LevelDefinition] = LevelCatalog.standard.levels) {
        let record = store.load().record
        self.record = record
        self.store = store
        self.services = services
        self.language = record.language
        self.musicOn = record.musicOn
        self.totalStars = record.totalStars
        self.completedLevels = record.completedLevels
        self.trail = TrailViewModel(catalog: LevelCatalog(levels: curriculum), record: record,
                                    language: record.language, services: services)
    }

    /// Loads the store and surfaces its notice without blocking; never writes.
    public func launch() {
        let loaded = store.load()
        record = loaded.record
        language = record.language
        musicOn = record.musicOn
        totalStars = record.totalStars
        completedLevels = record.completedLevels
        trail.update(record: record, language: language)
        switch loaded.notice {
        case .missingFile: notice = "notice.save-missing"
        case .corruptFile: notice = "notice.save-corrupt"
        case .unsupportedVersion: notice = "notice.save-unsupported"
        case nil: notice = nil
        }
    }

    public func sceneDidEnterBackground() {
        persist()
    }

    /// Saves a child-made rhythm as symbolic events in the creations.
    public func saveMusicPattern(_ pattern: MusicA4Pattern) {
        record.creations.save(pattern)
        persist()
    }

    private func persist() {
        let report = store.save(record)
        lastSave = report
        if !report.success {
            notice = "notice.save-failed"
        } else if notice?.hasPrefix("notice.save-") == true {
            notice = nil
        }
    }

    /// Title or icon tap: back to the welcome screen. An unfinished round is dropped unscored;
    /// a finished one keeps its awarded stars. Diagnostics visibility is untouched.
    public func goHome() {
        round = nil
        screen = .welcome
    }

    /// Title long-press (3 s): opens diagnostics and never navigates.
    public func titleLongPressCompleted() {
        diagnosticsVisible = true
        setDeveloperMode(true)
    }

    /// Session-only developer mode: every level reads unlocked; the record is untouched.
    public var developerMode: Bool { trail.developerMode }

    public func setDeveloperMode(_ on: Bool) {
        trail.developerMode = on
    }

    /// Replaces the record with a clean one and saves it at once; does nothing unless confirmed.
    public func resetAllProgress(confirmed: Bool) {
        guard confirmed else { return }
        var clean = ProgressRecord.fresh()
        clean.language = record.language
        clean.musicOn = record.musicOn
        record = clean
        totalStars = record.totalStars
        completedLevels = record.completedLevels
        trail.update(record: record, language: language)
        persist()
    }

    public func setDiagnosticsVisible(_ visible: Bool) {
        diagnosticsVisible = visible
    }

    /// Back control: leaves an unfinished round for the trail, dropping it.
    public func leaveRound() {
        guard screen == .round else { return }
        round = nil
        screen = .trail
    }

    public func play() {
        startMusicIfNeeded()
        if screen == .welcome { screen = .trail }
    }

    /// Music starts lazily on the first user action, and only when the music switch is on.
    private func startMusicIfNeeded() {
        guard musicOn, !musicStarted else { return }
        musicStarted = true
        services.audio.setMusic(on: true)
    }

    public func startLevel(_ levelId: String) {
        startMusicIfNeeded()
        guard screen == .trail, let model = trail.startRound(levelId: levelId) else { return }
        open(model)
    }

    private func open(_ model: RoundViewModel) {
        model.onComplete = { [weak self] in self?.showSummary() }
        model.onAbandon = { [weak self, weak model] in
            guard let self, let model, self.round === model else { return }
            self.leaveRound()
        }
        round = model
        screen = .round
        services.audio.roundChanged()
    }

    /// Opens the audit state: the seeded record replaces any saved one, a question stop opens its
    /// exact level, seed and question, and the summary stop shows the three stars just earned.
    public func applyAudit(_ state: AuditLaunchState) {
        record = state.record
        language = record.language
        totalStars = record.totalStars
        completedLevels = record.completedLevels
        trail.update(record: record, language: language)
        switch state.screen {
        case .welcome: break
        case .round:
            screen = .trail
            let round = Round(levelId: state.levelId, seed: state.seed).starting(at: state.questionIndex)
            open(RoundViewModel(round: round, language: language, haptics: services.haptics))
        case .summary:
            record.recordRound(RoundEntry(levelId: state.levelId, date: Date(timeIntervalSince1970: 0),
                                          firstTryCount: ProgressRecord.starsPerRound, helpUsed: false))
            totalStars = record.totalStars
            screen = .summary
        default: screen = .trail
        }
    }

    public func setLanguage(_ newLanguage: Language) {
        language = newLanguage
        record.language = newLanguage
        persist()
        round?.setLanguage(newLanguage)
        trail.update(record: record, language: newLanguage)
    }

    public func setMusic(_ on: Bool) {
        musicOn = on
        musicStarted = on
        services.audio.setMusic(on: on)
        record.musicOn = on
        trail.update(record: record, language: language)
        persist()
    }

    /// Explicit ear tap: the only path that speaks.
    public func listen() { speakPrompt() }

    /// Tap to Hear for a kit reading item: the syllable or word, through the round's own command.
    public func hear() { round?.hear(speech: services.speech) }

    /// Tap to Hear on a sentence question: the whole sentence, in the sentence's own language.
    public func hearSentence(_ question: SentenceQuestion) {
        speak(question.speechText, voiceTag: question.voiceTag)
    }

    /// Speaks the current prompt with the music ducked; failures never block the round.
    public func speakPrompt() {
        guard let round else { return }
        speak(round.speechText, voiceTag: language == .fr ? "fr-FR" : "en-US")
    }

    /// One explicit speech call: music ducked, a missing voice noted, never called on its own.
    private func speak(_ text: String, voiceTag: String) {
        var mixer = BusMixer()
        mixer.speechWillStart()
        services.audio.setMusicLevel(mixer.musicGain)
        services.audio.speechWillStart()
        defer {
            mixer.speechDidEnd()
            services.audio.speechDidEnd()
            services.audio.setMusicLevel(mixer.musicGain)
        }
        let outcome = try? services.speech.speak(voiceTag: voiceTag, text: text)
        notice = outcome == .voiceMissing ? "notice.voice-missing" : nil
    }

    /// Only clears the round and returns to the trail; the commit happened when the summary appeared.
    public func leaveSummary() {
        guard screen == .summary else { return }
        round = nil
        screen = .trail
    }

    /// Shows the summary and commits the stars and completion once, saving atomically.
    private func showSummary() {
        commitSummary()
        screen = .summary
        if celebrationEntry != nil { services.audio.play(MotifTable.celebration, on: .effects) }
    }

    /// The finished round shown on the summary; nil before one is committed.
    private var celebrationEntry: RoundEntry? { record.stars.history.last }

    /// The one celebration for the round on the summary screen.
    public func celebrationPlan(reduceMotion: Bool) -> CelebrationPlan? {
        celebrationEntry.map { CelebrationPlan($0, reduceMotion: reduceMotion) }
    }

    /// The star button's presentation, the same on every screen.
    public var starButton: StarButton {
        ChromePresentation.starButton(for: screen, record: record, language: language)
    }

    /// The star button opens the terrarium from any screen without touching the round.
    public func openTerrarium() { terrariumVisible = true }

    public func setTerrariumVisible(_ visible: Bool) { terrariumVisible = visible }

    private func commitSummary() {
        guard let finished = round, finished.summary != nil, committedRound !== finished else { return }
        committedRound = finished
        trail.commit(finished)
        record = trail.record
        persist()
        totalStars = record.totalStars
        completedLevels = record.completedLevels
    }
}
