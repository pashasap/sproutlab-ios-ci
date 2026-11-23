/// Pure layout decisions; they depend only on the width they are given, never on the device type.
public enum LayoutPolicy {
    public static let sideBySideMinimumWidth: Double = 600
    public static let maximumTrailColumns = 3

    public static func usesSideBySide(width: Double) -> Bool {
        width >= sideBySideMinimumWidth
    }

    /// Trail lanes: one column on narrow widths or a compact size class, one column per lane beside each other on wide.
    public static func trailColumns(width: Double, isCompactSizeClass: Bool, laneCount: Int) -> Int {
        guard !isCompactSizeClass, usesSideBySide(width: width) else { return 1 }
        return max(1, min(laneCount, maximumTrailColumns))
    }
}

/// What a screen renders: the bar is always pinned; the content scrolls only when it does not fit below the bar.
public struct ScreenLayout: Equatable {
    public let topBarPinned: Bool
    public let contentScrolls: Bool
}

extension LayoutPolicy {
    /// Height reserved for the top bar, in points.
    public static let topBarHeight: Double = 72

    public static func screenLayout(availableHeight: Double, contentHeight: Double) -> ScreenLayout {
        ScreenLayout(topBarPinned: true,
                     contentScrolls: contentHeight > availableHeight - topBarHeight)
    }
}

public enum Touch {
    /// Minimum side of every interactive control, in points.
    public static let minimumPoints: Double = 56
}

public struct SafeInsets: Equatable, Sendable {
    public let top: Double
    public let leading: Double
    public let bottom: Double
    public let trailing: Double

    public init(top: Double, leading: Double, bottom: Double, trailing: Double) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
}

public struct LayoutRect: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var minX: Double { x }
    public var maxX: Double { x + width }
    public var minY: Double { y }
    public var maxY: Double { y + height }
}

public struct ScreenMetrics: Equatable, Sendable {
    public let width: Double
    public let height: Double
    public let insets: SafeInsets

    public init(width: Double, height: Double, insets: SafeInsets) {
        self.width = width
        self.height = height
        self.insets = insets
    }

    public var safeRect: LayoutRect {
        LayoutRect(x: insets.leading, y: insets.top,
                   width: max(0, width - insets.leading - insets.trailing),
                   height: max(0, height - insets.top - insets.bottom))
    }
}

public enum TextScale: Sendable {
    case standard, xl

    var factor: Double { self == .xl ? 1.3 : 1.0 }
}

public struct TerrariumControlFrames: Equatable, Sendable {
    public let close: LayoutRect
    public let journal: LayoutRect
    public let panLeft: LayoutRect
    public let panRight: LayoutRect
    public let dial: LayoutRect
}

public struct SlotBoardLayout: Equatable, Sendable {
    public let slotRows: [[Int]]
    public let tileRows: [[Int]]
    public let slotRowWidths: [Double]
    public let tileRowWidths: [Double]
}

public struct NumberTrackLayout: Equatable, Sendable {
    public let cellWidth: Double
    public let rows: [[Int]]
    public let rowWidths: [Double]
}

public struct ComparisonLayout: Equatable, Sendable {
    public let leftCard: LayoutRect
    public let rightCard: LayoutRect
    public let answerArea: LayoutRect
    public let leftDots: [LayoutRect]
    public let rightDots: [LayoutRect]
}

extension LayoutPolicy {
    public static let controlSide: Double = Touch.minimumPoints
    public static let controlMargin: Double = 8
    public static let maximumSlotBoardTiles = 12
    static let cellSpacing: Double = 8

    public static let viewportMargin: Double = 16

    /// Positions come from the viewport only; the scene width is accepted but ignored.
    public static func terrariumControls(_ screen: ScreenMetrics, sceneWidth: Double) -> TerrariumControlFrames {
        terrariumControls(screen)
    }

    public static func terrariumControls(_ screen: ScreenMetrics) -> TerrariumControlFrames {
        let safe = screen.safeRect
        let side = controlSide
        let margin = viewportMargin
        let midY = safe.minY + max(0, (safe.height - side) / 2)
        func frame(_ x: Double, _ y: Double) -> LayoutRect {
            LayoutRect(x: x, y: y, width: side, height: side)
        }
        return TerrariumControlFrames(
            close: frame(safe.minX + margin, safe.minY + controlMargin),
            journal: frame(safe.maxX - margin - side, safe.minY + controlMargin),
            panLeft: frame(safe.minX + margin, midY),
            panRight: frame(safe.maxX - margin - side, midY),
            dial: frame(safe.minX + max(0, (safe.width - side) / 2),
                        safe.maxY - controlMargin - side))
    }

    public static let terrariumResidentSide: Double = 64
    static let terrariumColumnCentres: [Double] = [0.275, 0.50, 0.725]
    static let terrariumRowCount = 5

    /// Residents sit on a 3 x 5 grid inside the viewport; rows run from y = 140 to height - 160.
    public static func terrariumResidentPosition(index: Int, total: Int, screen: ScreenMetrics) -> LayoutRect {
        let slot = max(0, min(index, max(1, total) - 1))
        let columns = terrariumColumnCentres.count
        let top = 140.0, bottom = screen.height - 160
        let step = terrariumRowCount > 1 ? (bottom - top) / Double(terrariumRowCount - 1) : 0
        let row = min(slot / columns, terrariumRowCount - 1)
        let side = terrariumResidentSide
        let centreX = screen.width * terrariumColumnCentres[slot % columns]
        return LayoutRect(x: centreX - side / 2, y: top + Double(row) * step - side / 2, width: side, height: side)
    }

    private static func wrap(count: Int, cell: Double, availableWidth: Double) -> (rows: [[Int]], widths: [Double]) {
        let fit = max(1, Int(((availableWidth + cellSpacing) / (cell + cellSpacing)).rounded(.down)))
        let perRow = min(fit, maximumSlotBoardTiles)
        var rows: [[Int]] = []
        var start = 0
        while start < count {
            let end = min(count, start + perRow)
            rows.append(Array(start..<end))
            start = end
        }
        if rows.isEmpty { rows = [[]] }
        let widths = rows.map { $0.isEmpty ? 0 : Double($0.count) * cell + Double($0.count - 1) * cellSpacing }
        return (rows, widths)
    }

    public static func slotBoard(slotCount: Int, tileCount: Int, availableWidth: Double) -> SlotBoardLayout {
        let slots = wrap(count: slotCount, cell: Touch.minimumPoints, availableWidth: availableWidth)
        let tiles = wrap(count: tileCount, cell: Touch.minimumPoints, availableWidth: availableWidth)
        return SlotBoardLayout(slotRows: slots.rows, tileRows: tiles.rows,
                               slotRowWidths: slots.widths, tileRowWidths: tiles.widths)
    }

    public static func numberTrack(numbers: [Int], availableWidth: Double, textScale: TextScale) -> NumberTrackLayout {
        let digits = numbers.map { String(abs($0)).count }.max() ?? 1
        let glyphs = Double(digits) * 0.6 * 17 * textScale.factor
        let cell = max(Touch.minimumPoints, (glyphs + 16).rounded(.up))
        let perRow = max(1, Int(((availableWidth + cellSpacing) / (cell + cellSpacing)).rounded(.down)))
        var rows: [[Int]] = []
        var start = 0
        while start < numbers.count {
            let end = min(numbers.count, start + perRow)
            rows.append(Array(numbers[start..<end]))
            start = end
        }
        let widths = rows.map { Double($0.count) * cell + Double($0.count - 1) * cellSpacing }
        return NumberTrackLayout(cellWidth: cell, rows: rows, rowWidths: widths)
    }

    public static func comparisonLayout(_ screen: ScreenMetrics, leftCount: Int, rightCount: Int) -> ComparisonLayout {
        let safe = screen.safeRect
        let margin = 16.0, gap = 12.0, pad = 8.0, columns = 3
        let cardWidth = max(0, (safe.width - 2 * margin - gap) / 2)
        let rowsNeeded = max(1, (max(leftCount, rightCount) + columns - 1) / columns)
        let dot = max(8, min(36, (cardWidth - 2 * pad - Double(columns - 1) * 6) / Double(columns)))
        let cardHeight = 2 * pad + Double(rowsNeeded) * dot + Double(rowsNeeded - 1) * 6
        let top = safe.minY + topBarHeight
        let left = LayoutRect(x: safe.minX + margin, y: top, width: cardWidth, height: cardHeight)
        let right = LayoutRect(x: left.maxX + gap, y: top, width: cardWidth, height: cardHeight)
        let answerHeight = 72.0
        let answer = LayoutRect(x: safe.minX + margin, y: max(left.maxY + margin, safe.maxY - margin - answerHeight),
                                width: max(0, safe.width - 2 * margin), height: answerHeight)
        func dots(_ count: Int, in card: LayoutRect) -> [LayoutRect] {
            (0..<count).map { index in
                LayoutRect(x: card.x + pad + Double(index % columns) * (dot + 6),
                           y: card.y + pad + Double(index / columns) * (dot + 6),
                           width: dot, height: dot)
            }
        }
        return ComparisonLayout(leftCard: left, rightCard: right, answerArea: answer,
                                leftDots: dots(leftCount, in: left), rightDots: dots(rightCount, in: right))
    }
}
