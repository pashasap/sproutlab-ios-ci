import SwiftUI
import Core

/// Letter or syllable tiles; the selected tile is outlined in the activity colour passed to Core.
/// The visible target or split word (`stimulusWord`) is shown above the movable tiles.
struct KitTileSetView: View {
    let tiles: KitTileSet
    let language: Language
    let send: (KitCommand) -> Void
    var stimulusWord: String = ""

    var body: some View {
        let actions = tiles.accessibilityActions
        VStack(spacing: 16) {
            if !stimulusWord.isEmpty {
                Text(stimulusWord)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Palette.ink)
                    .accessibilityIdentifier(KitIdentifier.make("word"))
            }
            HStack(spacing: 12) {
                ForEach(tiles.tapTargets, id: \.identifier) { target in
                    KitTargetButton(target: target, label: target.label(for: actions, language),
                                    action: send) {
                        Text(target.subject ?? "").foregroundStyle(Palette.ink)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(Palette.activity(tiles.highlightColourToken), lineWidth: 4)
                        .opacity(target.subject == tiles.selectedToken ? 1 : 0))
                }
            }
        }
        .kitActions(actions, language: language) { send($0.command) }
        .kitAnnounce(tiles.announcements, language: language)
    }
}
