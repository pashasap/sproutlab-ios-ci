import SwiftUI
import Core

struct TrailView: View {
    let app: AppViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        GeometryReader { proxy in
            let trail = presentation(in: proxy.size)
            ScrollView {
                VStack(spacing: trail.spacing) {
                    heading.frame(minHeight: trail.titleHeight)
                    lanes(trail)
                    if let key = app.notice {
                        Text(TextTable.string(key, app.language))
                            .font(.callout)
                            .foregroundStyle(Palette.locked)
                    }
                }
                .padding(trail.inset)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func presentation(in size: CGSize) -> TrailStopPresentation {
        // This view's local viewport already excludes the safe area and the pinned bar.
        let viewport = ScreenMetrics(width: Double(size.width), height: Double(size.height) + LayoutPolicy.topBarHeight,
                                     insets: SafeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        let scale: TextScale = typeSize <= .large ? .standard : .xl
        return app.trail.stopPresentation(viewport: viewport, textScale: scale,
                                          isCompactSizeClass: sizeClass == .compact)
    }

    private var heading: some View {
        HStack(spacing: 8) {
            Image(systemName: ChromeCatalog.symbolName(for: .trail)).accessibilityHidden(true)
            Text(TextTable.string("trail.title", app.language))
        }
        .font(.title.weight(.bold))
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(Palette.ink)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func lanes(_ trail: TrailStopPresentation) -> some View {
        let column = GridItem(.flexible(), spacing: trail.spacing, alignment: .top)
        let columns = Array(repeating: column, count: trail.columnCount)
        return LazyVGrid(columns: columns, alignment: .center, spacing: trail.spacing) {
            ForEach(trail.lanes, id: \.track) { lane in
                laneColumn(lane, spacing: trail.spacing)
            }
        }
        .frame(width: trail.contentWidth)
    }

    /// The heading from Core's TrailLaneHeaders.header stays above the row as its tiles scroll sideways.
    private func laneColumn(_ lane: TrailLanePresentation, spacing: Double) -> some View {
        VStack(alignment: .leading, spacing: lane.headingSpacing) {
            laneHeading(lane)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(lane.tiles, id: \.levelId) { tile in
                        TrailTileView(tile: tile, language: app.language) { app.startLevel(tile.levelId) }
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func laneHeading(_ lane: TrailLanePresentation) -> some View {
        HStack(spacing: 8) {
            Image(systemName: lane.header.symbolName).accessibilityHidden(true)
            Text(lane.header.title)
        }
        .font(.headline)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, minHeight: lane.headingFrame.height, alignment: .leading)
        .foregroundStyle(Palette.locked)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
