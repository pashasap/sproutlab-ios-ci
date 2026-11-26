import SwiftUI
import Core

/// Draws the Math M1 stimulus from Core presentation data: objects, tray slots, counted marks, match groups.
struct M1View: View {
    let shown: M1Presentation
    let label: String

    var body: some View {
        VStack(spacing: 12) {
            if let first = shown.groups.first {
                collection(first, marks: shown.countedMarks)
            }
            if !shown.traySlots.isEmpty { tray }
            if !shown.choiceGroups.isEmpty { matchRow }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityIdentifier(SproutIdentifier.stimulus)
    }

    private func collection(_ group: M1Collection, marks: [Bool]) -> some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(Array(group.objects.enumerated()), id: \.offset) { index, object in
                    let side = 30 * object.size
                    let counted = marks.indices.contains(index) && marks[index]
                    objectView(index: index, object: object)
                        .frame(width: side, height: side)
                        .overlay(Circle().stroke(Palette.ink, lineWidth: counted ? 3 : 0))
                        .position(x: object.x * (proxy.size.width - 32) + 16,
                                  y: object.y * (proxy.size.height - 32) + 16)
                }
            }
        }
        .frame(height: 140)
    }

    /// One counted object, drawn by the shared recipe renderer from a garden resident recipe.
    @ViewBuilder
    private func objectView(index: Int, object: M1Object) -> some View {
        if let recipe = creature(index: index, object: object) {
            RecipeRenderer(recipe: recipe, scheme: .light)
        } else {
            Circle().fill(Palette.dot)
        }
    }

    private func creature(index: Int, object: M1Object) -> Recipe? {
        let recipes = Recipe.table
        guard !recipes.isEmpty else { return nil }
        return recipes[abs(index * 5 + Int(object.x * 100)) % recipes.count]
    }

    private var tray: some View {
        HStack(spacing: 6) {
            ForEach(Array(shown.traySlots.enumerated()), id: \.offset) { _, slot in
                RoundedRectangle(cornerRadius: 6)
                    .fill(slot.isFilled ? Palette.dot : Palette.card)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.ink, lineWidth: 2))
                    .frame(width: 26, height: 26)
            }
        }
    }

    private var matchRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(shown.choiceGroups.enumerated()), id: \.offset) { _, group in
                collection(group, marks: []).frame(height: 90)
            }
        }
    }
}
