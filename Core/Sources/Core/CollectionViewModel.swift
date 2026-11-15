import Foundation
import Observation

public protocol ClockService: Sendable {
    func now() -> Date
}

public struct SystemClock: ClockService {
    public init() {}
    public func now() -> Date { Date() }
}

@MainActor
@Observable
public final class CollectionViewModel {
    public private(set) var record: ProgressRecord
    private let store: any ProgressStore
    private let clock: any ClockService

    public init(store: any ProgressStore, clock: any ClockService) {
        self.store = store
        self.clock = clock
        self.record = store.load().record
    }

    public func state(of id: String) -> CollectibleState {
        guard let item = Collectible.find(id) else { return .notArrived }
        return CollectionEvaluator.state(for: item, record: record)
    }

    /// Records a journal stamp for a met resident; nothing else changes.
    public func recordStamp(_ stamp: Stamp, for id: String) {
        guard state(of: id) == .met else { return }
        var next = record
        next.recordStamp(stamp, for: id)
        guard next != record, store.save(next).success else { return }
        record = next
    }

    /// Welcomes a ready collectible once. Never spends stars. True only when a new entry was saved.
    @discardableResult
    public func welcome(_ id: String) -> Bool {
        guard state(of: id) == .ready else { return false }
        var next = record
        next.collection.welcomed.append(WelcomeEntry(id: id, date: clock.now()))
        guard store.save(next).success else { return false }
        record = next
        return true
    }
}
