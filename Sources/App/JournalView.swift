import SwiftUI
import Core

/// Thin renderer of `JournalScreen`: every value comes from Core.
/// The book icon (sproutlab.journal) in the terrarium opens it; its identifiers are defined in Core.
struct JournalView: View {
    let model: TerrariumViewModel
    let onBack: () -> Void

    var body: some View {
        let screen = model.journalScreen
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: TextTable.string(screen.closeControl.iconKey, .en)).font(.title)
                }
                .frame(width: screen.closeControl.width, height: screen.closeControl.height)
                .accessibilityLabel(screen.closeControl.label(model.language))
                .accessibilityIdentifier(screen.closeControl.accessibilityId)
                Text(screen.title).font(.title2.weight(.semibold))
            }
            pips(screen.garden)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(screen.cards, id: \.id) { card in cardView(card) }
                }
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(ChromeCatalog.journalScreenIdentifier)
        .onAppear { model.openJournal() }
    }

    private func pips(_ garden: JournalGarden) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(garden.pips.enumerated()), id: \.offset) { _, filled in
                Image(systemName: TextTable.string(JournalModel.arrivalIconKey, .en)).font(.caption)
                    .opacity(filled ? 1 : 0.25)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(garden.pipsLabel)
    }

    @ViewBuilder
    private func cardView(_ card: JournalCard) -> some View {
        HStack(spacing: 12) {
            if let ear = card.ear {
                metCard(card, ear)
            } else {
                lockedCard(card)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .accessibilityElement(children: .contain)
    }

    private func lockedCard(_ card: JournalCard) -> some View {
        HStack(spacing: 8) {
            if let recipe = Recipe.table.first(where: { $0.id == card.id }) {
                RecipeRenderer(recipe: recipe, scheme: .light)
                    .frame(width: 64, height: 64).saturation(0).opacity(0.4)
            }
            if let key = card.arrivalIcon ?? card.trackIcon {
                Image(systemName: TextTable.string(key, .en))
            }
            if let stars = card.milestoneStars ?? card.starFallback {
                Text(String(stars))
                Image(systemName: TextTable.string(JournalModel.arrivalIconKey, .en))
            }
            if let label = card.welcomeLabel {
                Button { _ = model.welcome(card.id) } label: {
                    Image(systemName: TextTable.string("icon.hand", .en))
                }
                .frame(width: 56, height: 56)
                .accessibilityLabel(label)
            }
        }
    }

    private func metCard(_ card: JournalCard, _ ear: JournalEar) -> some View {
        HStack(spacing: 8) {
            Button { model.tap(card.id) } label: {
                if let recipe = Recipe.table.first(where: { $0.id == card.id }) {
                    RecipeRenderer(recipe: recipe, scheme: .light).frame(width: 64, height: 64)
                }
            }
            .accessibilityLabel(ear.name)
            VStack(alignment: .leading) {
                Text(ear.name).font(.headline)
                Text(ear.fact).font(.subheadline)
                HStack {
                    ForEach(card.stamps, id: \.self) { stamp in
                        Image(systemName: TextTable.string(JournalScreen.stampIconKey(stamp), .en))
                            .accessibilityLabel(TextTable.string(JournalScreen.stampLabelKey(stamp), model.language))
                    }
                }
            }
        }
    }
}
