import Foundation

/// Cell edge lengths of the creature gallery. The smallest stays hit-capable.
public enum GallerySize: CaseIterable, Sendable {
    case small, medium, large

    public var points: Double {
        switch self {
        case .small: return 56
        case .medium: return 112
        case .large: return 160
        }
    }

    var textKey: String {
        switch self {
        case .small: return "gallery.size.small"
        case .medium: return "gallery.size.medium"
        case .large: return "gallery.size.large"
        }
    }
}

public enum GalleryScheme: CaseIterable, Sendable {
    case light, dark

    var textKey: String {
        self == .light ? "gallery.scheme.light" : "gallery.scheme.dark"
    }

    /// The Core colour scheme used to resolve tokens for this cell.
    public var colourScheme: ColourScheme {
        self == .light ? .light : .dark
    }
}

public struct GalleryCell: Equatable, Sendable {
    public var residentId: String
    public var size: GallerySize
    public var scheme: GalleryScheme
}

public struct GalleryRow: Equatable, Sendable {
    public var residentId: String
    public var sizes: [GallerySize]
    public var schemes: [GalleryScheme]
}

extension TextTable {
    static let galleryTexts: [String: TextEntry] = [
        "gallery.title": TextEntry("Galerie des créatures", "Creature gallery"),
        "gallery.open": TextEntry("Galerie", "Gallery"),
        "gallery.size.small": TextEntry("petit", "small"),
        "gallery.size.medium": TextEntry("moyen", "medium"),
        "gallery.size.large": TextEntry("grand", "large"),
        "gallery.scheme.light": TextEntry("mode clair", "light mode"),
        "gallery.scheme.dark": TextEntry("mode sombre", "dark mode")
    ]
}

/// Lays out every recipe at every size in both schemes; the view only renders these values.
public struct GalleryModel: Sendable {
    public let rows: [GalleryRow]
    public let cells: [GalleryCell]

    public init() {
        let rows = Recipe.table.map {
            GalleryRow(residentId: $0.id, sizes: GallerySize.allCases, schemes: GalleryScheme.allCases)
        }
        self.rows = rows
        self.cells = rows.flatMap { row in
            row.sizes.flatMap { size in
                row.schemes.map { GalleryCell(residentId: row.residentId, size: size, scheme: $0) }
            }
        }
    }

    /// The cells of one row in one scheme, smallest size first.
    public func cells(in row: GalleryRow, scheme: GalleryScheme) -> [GalleryCell] {
        cells.filter { $0.residentId == row.residentId && $0.scheme == scheme }
    }

    public func recipe(for cell: GalleryCell) -> Recipe? {
        Recipe.table.first { $0.id == cell.residentId }
    }

    public func accessibilityLabel(for cell: GalleryCell, language: Language) -> String {
        let name = TextTable.string("recipe.\(cell.residentId).name", language)
        let size = TextTable.string(cell.size.textKey, language)
        let scheme = TextTable.string(cell.scheme.textKey, language)
        return "\(name), \(size), \(scheme)"
    }
}
