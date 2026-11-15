import Foundation

public struct GardenPoint: Equatable, Sendable {
    public let x: Double
    public let y: Double
}

/// Origin top-left, scene coordinates.
public struct GardenRect: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public func contains(_ point: GardenPoint) -> Bool {
        point.x >= x && point.x <= x + width && point.y >= y && point.y <= y + height
    }
}

public struct GardenLayer: Equatable, Sendable {
    public let id: String
    public let parallax: Double
    public let elementIds: [String]
}

/// The layered garden: about 2.5 screens wide, five layers, each with a parallax factor.
public struct GardenScene: Equatable, Sendable {
    public let width: Double
    public let height: Double
    public let screenWidth: Double
    public let layers: [GardenLayer]
    public let glassTank: GardenRect
    public let underground: GardenRect
    public let spots: [String: GardenPoint]

    public var maxPanOffset: Double { max(0, width - screenWidth) }

    public static let garden = GardenScene(
        width: 1000, height: 800, screenWidth: 400,
        layers: [
            GardenLayer(id: "sky", parallax: 0.1, elementIds: ["sun", "clouds"]),
            GardenLayer(id: "farHills", parallax: 0.3, elementIds: ["hills"]),
            GardenLayer(id: "midHedge", parallax: 0.6, elementIds: ["hedge", "log-pile"]),
            GardenLayer(id: "stage", parallax: 1.0, elementIds: [
                "ground", "plants", "creatures", "garden-table", "glass-tank",
                "underground", "roots", "ant-nest"]),
            GardenLayer(id: "nearGrass", parallax: 1.4, elementIds: ["grass-left", "grass-right"])
        ],
        glassTank: GardenRect(x: 700, y: 380, width: 180, height: 140),
        underground: GardenRect(x: 120, y: 600, width: 400, height: 160),
        spots: [
            "sunflower": GardenPoint(x: 150, y: 450),
            "earthworm": GardenPoint(x: 330, y: 690),
            "ant": GardenPoint(x: 200, y: 680),
            "fern": GardenPoint(x: 450, y: 470),
            "ladybug": GardenPoint(x: 560, y: 440),
            "tree-frog": GardenPoint(x: 620, y: 540),
            "glowing-mushroom": GardenPoint(x: 440, y: 720),
            "axolotl": GardenPoint(x: 790, y: 460),
            "butterfly": GardenPoint(x: 930, y: 300),
            "honeybee": GardenPoint(x: 280, y: 330),
            "snail": GardenPoint(x: 540, y: 640),
            "poppy": GardenPoint(x: 70, y: 540),
            "dandelion": GardenPoint(x: 640, y: 330),
            "robin": GardenPoint(x: 860, y: 600),
            "cricket": GardenPoint(x: 700, y: 700)
        ])

    /// A tap area of `side` points centred on the position, kept inside the scene.
    public func tapArea(around point: GardenPoint, side: Double) -> GardenRect {
        let x = min(max(point.x - side / 2, 0), width - side)
        let y = min(max(point.y - side / 2, 0), height - side)
        return GardenRect(x: x, y: y, width: side, height: side)
    }
}
