/// The Explorer Trail at its initial scroll position; lanes and tiles stay in curriculum order.
public struct TrailStopPresentation: Equatable, Sendable {
    public let lanes: [TrailLanePresentation]
    public let columnCount: Int
    public let contentWidth: Double
    public let inset: Double
    public let spacing: Double
    public let titleHeight: Double
}

public struct TrailLanePresentation: Equatable, Sendable {
    public let track: String
    public let header: TrailLaneHeader
    public let headingFrame: LayoutRect
    public let tiles: [TrailTileLayout]
    public let headingSpacing: Double
    /// The heading and one row of tiles at the design-token size.
    public let contentHeight: Double
    /// Native text can wrap and make the row taller, never cut it off.
    public var fixedHeight: Double? { nil }
}

public struct TrailTileLayout: Equatable, Sendable {
    public let levelId: String
    public let presentation: TrailTilePresentation
    public let frame: LayoutRect
    public let isVisibleAtStop: Bool

    public var spokenLabel: String { presentation.accessibilityLabel }
    public var touchWidth: Double { frame.width }
    public var touchHeight: Double { frame.height }
}

extension TrailViewModel {
    public func stopPresentation(viewport: ScreenMetrics, textScale: TextScale,
                                 isCompactSizeClass: Bool = false) -> TrailStopPresentation {
        let lanes = lanes()
        let columns = LayoutPolicy.trailColumns(width: viewport.safeRect.width,
                                                isCompactSizeClass: isCompactSizeClass, laneCount: lanes.count)
        let layout = TrailBoardLayout(safe: viewport.safeRect, columns: columns, textScale: textScale)
        return layout.presentation(lanes, language: language)
    }
}

/// Frames describe the design-token sizes; the view uses heights as minimums, not clipping bounds.
private struct TrailBoardLayout {
    let safe: LayoutRect
    let columns: Int
    let textScale: TextScale
    let inset = LayoutPolicy.viewportMargin
    let spacing = 12.0
    let headingSpacing = 8.0

    var contentWidth: Double {
        let width = max(0, safe.width - 2 * inset)
        return columns == 1 ? min(width, 640) : width
    }
    var columnWidth: Double { max(0, (contentWidth - Double(columns - 1) * spacing) / Double(columns)) }
    var titleHeight: Double { 38 * textScale.factor }
    var headingHeight: Double { 26 * textScale.factor }
    var tileHeight: Double { 112 * textScale.factor }
    var laneHeight: Double { headingHeight + headingSpacing + tileHeight }

    var tileWidth: Double {
        // Aim for two tiles and a glimpse of the next one. Narrow tablet columns can show one instead.
        let pairWidth = (columnWidth - 3 * spacing) / 2
        return max(Touch.minimumPoints, min(columnWidth, max(128, min(176, pairWidth.rounded(.down)))))
    }

    func presentation(_ lanes: [TrailLane], language: Language) -> TrailStopPresentation {
        let presented = lanes.enumerated().map { index, lane in
            lanePresentation(lane, index: index, language: language)
        }
        return TrailStopPresentation(lanes: presented, columnCount: columns, contentWidth: contentWidth,
                                     inset: inset, spacing: spacing, titleHeight: titleHeight)
    }

    private func lanePresentation(_ lane: TrailLane, index: Int, language: Language) -> TrailLanePresentation {
        let leading = safe.minX + (safe.width - contentWidth) / 2
        let x = leading + Double(index % columns) * (columnWidth + spacing)
        let top = safe.minY + LayoutPolicy.topBarHeight + inset + titleHeight + spacing
        let y = top + Double(index / columns) * (laneHeight + spacing)
        let heading = LayoutRect(x: x, y: y, width: columnWidth, height: headingHeight)
        let tiles = lane.tiles.enumerated().map { offset, tile in
            tileLayout(tile, offset: offset, heading: heading)
        }
        let header = TrailLaneHeaders.header(forTrack: lane.track, language: language)
        return TrailLanePresentation(track: lane.track, header: header, headingFrame: heading, tiles: tiles,
                                     headingSpacing: headingSpacing, contentHeight: laneHeight)
    }

    private func tileLayout(_ tile: TrailTile, offset: Int, heading: LayoutRect) -> TrailTileLayout {
        let x = heading.minX + Double(offset) * (tileWidth + spacing)
        let frame = LayoutRect(x: x, y: heading.maxY + headingSpacing, width: tileWidth, height: tileHeight)
        let visible = frame.maxX <= heading.maxX && frame.maxY <= safe.maxY
        return TrailTileLayout(levelId: tile.levelId, presentation: tile.presentation, frame: frame,
                               isVisibleAtStop: visible)
    }
}
