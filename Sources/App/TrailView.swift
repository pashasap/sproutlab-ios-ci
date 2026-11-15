import SwiftUI
import Core

struct TrailView: View {
    let app: AppViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    heading
                    lanes(width: proxy.size.width)
                    if let key = app.notice {
                        Text(TextTable.string(key, app.language))
                            .font(.callout)
                            .foregroundStyle(Palette.locked)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var heading: some View {
        HStack(spacing: 8) {
            Image(systemName: ChromeCatalog.symbolName(for: .trail)).accessibilityHidden(true)
            Text(TextTable.string("trail.title", app.language))
        }
        .font(.title.weight(.bold))
        .foregroundStyle(Palette.ink)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func lanes(width: Double) -> some View {
        let lanes = app.trail.lanes()
        let count = LayoutPolicy.trailColumns(width: width, isCompactSizeClass: sizeClass == .compact,
                                              laneCount: lanes.count)
        let columns = Array(repeating: GridItem(.flexible(), alignment: .top), count: count)
        return LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
            ForEach(lanes, id: \.track) { lane in
                laneColumn(lane)
            }
        }
        .frame(maxWidth: count > 1 ? .infinity : 640)
    }

    private func laneColumn(_ lane: TrailLane) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: ChromeCatalog.symbolName(for: .math)).accessibilityHidden(true)
                Text(ChromeCatalog.icon(.math, language: app.language).accessibilityLabel)
                Spacer(minLength: 0)
            }
            .font(.headline)
            .foregroundStyle(Palette.locked)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            ForEach(lane.tiles, id: \.levelId) { tile in
                TrailTileView(tile: tile, language: app.language) { app.startLevel(tile.levelId) }
            }
        }
    }
}
