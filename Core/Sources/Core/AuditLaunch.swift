import Foundation

/// Where a progress record is kept.
public enum ProgressStoreKind: Equatable, Sendable {
    case inMemory, file
}

/// Keeps the record in memory only: nothing is read from or written to a file.
public final class InMemoryProgressStore: ProgressStore, @unchecked Sendable {
    private let lock = NSLock()
    private var record: ProgressRecord = .defaults

    public init() {}

    /// Saves that reached a file or any other persistent place; always 0.
    public var persistedSaveCount: Int { 0 }

    public func load() -> ProgressLoad {
        lock.withLock { ProgressLoad(record: record, notice: nil) }
    }

    public func save(_ record: ProgressRecord) -> SaveReport {
        lock.withLock { self.record = record }
        return SaveReport(time: Date(), success: true)
    }
}

/// The launch decision for `-auditStop <id>`: the stop state plus the isolated settings the app must use.
public struct AuditLaunch: Equatable, Sendable {
    public let stopId: String
    /// The accessibility identifier of the outermost view, from the audit catalog.
    public let root: String
    public let state: AuditStopState
    public let storeKind: ProgressStoreKind
    public let musicOn: Bool
    public let usesNetwork: Bool
    public let animationsEnabled: Bool
    public let seed: UInt64

    /// The launch for `argument`; nil for no argument or an unknown stop id.
    public static func resolve(argument: String?) -> AuditLaunch? {
        guard let argument,
              let stop = AuditStops.all.first(where: { $0.id == argument }),
              let state = AuditStopState.state(forStop: argument) else { return nil }
        return AuditLaunch(stopId: stop.id, root: stop.root, state: state, storeKind: .inMemory,
                           musicOn: false, usesNetwork: false, animationsEnabled: false, seed: state.seed)
    }

    public func makeStore() -> any ProgressStore {
        InMemoryProgressStore()
    }
}
