/// An ordered collection of level definitions; a level is added to the app purely as data.
public struct LevelCatalog: Sendable {
    public let levels: [LevelDefinition]

    public init(levels: [LevelDefinition]) {
        self.levels = levels
    }

    public static let standard = LevelCatalog(levels: Curriculum.all)

    /// Tracks in order of first appearance; levels keep catalog order inside their track.
    func tracks() -> [(track: String, levels: [LevelDefinition])] {
        var order: [String] = []
        for level in levels where !order.contains(level.track) { order.append(level.track) }
        return order.map { track in (track, levels.filter { $0.track == track }) }
    }

    /// The levels of the lane holding `levelId`, in order, or nil for an unknown id.
    func lane(containing levelId: String) -> [LevelDefinition]? {
        guard let level = levels.first(where: { $0.levelId == levelId }) else { return nil }
        return levels.filter { $0.track == level.track }
    }
}
