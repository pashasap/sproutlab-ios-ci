import Foundation

public enum RingSilhouette: Equatable, Sendable {
    case seed, egg, chrysalis
}

/// Progress toward the next star-driven arrival, from the record alone.
public struct RingProgress: Equatable, Sendable {
    public let fraction: Double
    public let nextArrivalId: String?
    public let silhouette: RingSilhouette
    public let isComplete: Bool
    private let total: Int
    private let target: Int

    public init(_ record: ProgressRecord) {
        let total = record.stars.total
        let steps: [(id: String, n: Int)] = Collectible.table.compactMap {
            if case .stars(let n) = $0.rule { return ($0.id, n) }
            return nil
        }
        let next = steps.sorted { $0.n < $1.n }.first { $0.n > total }
        self.total = total
        self.nextArrivalId = next?.id
        self.target = next?.n ?? (steps.map(\.n).max() ?? 0)
        self.isComplete = next == nil
        self.fraction = next == nil ? 1 : Double(max(total, 0)) / Double(next?.n ?? 1)
        self.silhouette = RingProgress.silhouette(next: next?.n)
    }

    private static func silhouette(next: Int?) -> RingSilhouette {
        guard let next else { return .chrysalis }
        if next <= 5 { return .seed }
        return next >= 24 ? .chrysalis : .egg
    }

    public func text(_ language: Language) -> String {
        if isComplete { return language == .fr ? "Tous les habitants sont arrivés" : "Everyone has arrived" }
        return language == .fr ? "\(total) sur \(target) étoiles" : "\(total) of \(target) stars"
    }
}
