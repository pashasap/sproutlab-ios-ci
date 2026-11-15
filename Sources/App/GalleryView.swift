import SwiftUI
import Core

/// Every recipe at three sizes in light and dark, laid out by the Core GalleryModel.
struct GalleryView: View {
    let language: Language
    private let model = GalleryModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text(TextTable.string("gallery.title", language))
                .font(.title2.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(model.rows, id: \.residentId) { row in
                        rowView(row)
                    }
                }
            }
            Button { dismiss() } label: {
                Text(TextTable.string("diag.close", language))
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .foregroundStyle(Palette.ink)
        .padding(12)
        .background(Palette.background.ignoresSafeArea())
    }

    private func rowView(_ row: GalleryRow) -> some View {
        VStack(spacing: 4) {
            Text(TextTable.string("recipe.\(row.residentId).name", language))
                .font(.headline)
            ForEach(row.schemes, id: \.self) { scheme in
                strip(model.cells(in: row, scheme: scheme), scheme: scheme)
            }
        }
    }

    private func strip(_ cells: [GalleryCell], scheme: GalleryScheme) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(cells, id: \.size) { cell in
                cellView(cell)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(ground(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func cellView(_ cell: GalleryCell) -> some View {
        if let recipe = model.recipe(for: cell) {
            RecipeRenderer(recipe: recipe, scheme: cell.scheme.colourScheme)
                .frame(width: cell.size.points, height: cell.size.points)
                .accessibilityElement()
                .accessibilityLabel(model.accessibilityLabel(for: cell, language: language))
        }
    }

    private func ground(_ scheme: GalleryScheme) -> Color {
        guard let value = ColourTokens.value(ColourTokens.gardenGround, scheme.colourScheme) else {
            return Palette.background
        }
        return Palette.colour(value)
    }
}
