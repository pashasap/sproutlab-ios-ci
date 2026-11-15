import Foundation

public enum CollectibleKind: String, Equatable, Codable, Sendable {
    case creature, decoration, habitat, tool
}

public enum UnlockRule: Equatable, Sendable {
    case free
    case stars(Int)
    case firstCompletion(levelId: String, starFallback: Int)
    case arrivesWithHabitat(String)
    case lifeStage(of: String, stage: Int)
}

public enum CollectibleState: Equatable, Sendable {
    case notArrived, ready, met
}

public struct Collectible: Equatable, Sendable {
    public let id: String
    public let kind: CollectibleKind
    public let nameFR: String
    public let nameEN: String
    public let article: String
    public let habitatId: String
    public let rule: UnlockRule
    public let milestone: Int

    public func name(_ language: Language) -> String {
        language == .fr ? nameFR : nameEN
    }

    private struct Spec {
        let names: (fr: String, en: String)
        let article: String
        let rule: UnlockRule
        let milestone: Int
    }

    private static func resident(_ id: String, _ spec: Spec) -> Collectible {
        Collectible(id: id, kind: .creature, nameFR: spec.names.fr, nameEN: spec.names.en,
                    article: spec.article, habitatId: "garden", rule: spec.rule,
                    milestone: spec.milestone)
    }

    /// The nine residents, in arrival order.
    public static let table: [Collectible] = [
        resident("sunflower", Spec(names: ("Tournesol", "Sunflower"), article: "le", rule: .free, milestone: 0)),
        resident("earthworm", Spec(names: ("Ver de terre", "Earthworm"), article: "le", rule: .free, milestone: 0)),
        resident("ant", Spec(names: ("Fourmi", "Ant"), article: "la", rule: .free, milestone: 0)),
        resident("fern", Spec(names: ("Fougère", "Fern"), article: "la", rule: .stars(2), milestone: 2)),
        resident("ladybug", Spec(names: ("Coccinelle", "Ladybug"), article: "la", rule: .stars(5), milestone: 5)),
        resident("tree-frog", Spec(names: ("Rainette", "Tree frog"), article: "la", rule: .stars(9), milestone: 9)),
        resident("glowing-mushroom", Spec(names: ("Champignon lumineux", "Glowing mushroom"),
                                          article: "le", rule: .stars(13), milestone: 13)),
        resident("axolotl", Spec(names: ("Axolotl", "Axolotl"), article: "l'", rule: .stars(18), milestone: 18)),
        resident("butterfly", Spec(names: ("Papillon", "Butterfly"), article: "le", rule: .stars(24), milestone: 24)),
        resident("honeybee", Spec(names: ("Abeille", "Honeybee"), article: "la", rule: .stars(27), milestone: 27)),
        resident("snail", Spec(names: ("Escargot", "Snail"), article: "l'", rule: .stars(30), milestone: 30)),
        resident("poppy", Spec(names: ("Coquelicot", "Poppy"), article: "le",
                               rule: .firstCompletion(levelId: firstLevel("reading", 0, "reading-first"), starFallback: 33),
                               milestone: 33)),
        resident("dandelion", Spec(names: ("Pissenlit", "Dandelion"), article: "le", rule: .stars(36), milestone: 36)),
        resident("robin", Spec(names: ("Rouge-gorge", "Robin"), article: "le",
                               rule: .firstCompletion(levelId: firstLevel("music", 0, "music-first"), starFallback: 39),
                               milestone: 39)),
        resident("cricket", Spec(names: ("Grillon", "Cricket"), article: "le",
                                 rule: .firstCompletion(levelId: firstLevel("music", 1, "music-second"), starFallback: 42),
                                 milestone: 42)),
    ]

    /// The level id at `index` in a track of the catalog; a stable placeholder id while the track has none.
    private static func firstLevel(_ track: String, _ index: Int, _ fallbackId: String) -> String {
        let ids = LevelCatalog.standard.levels.filter { $0.track == track }.map(\.levelId)
        return index < ids.count ? ids[index] : fallbackId
    }

    public static func find(_ id: String) -> Collectible? {
        table.first { $0.id == id }
    }
}
