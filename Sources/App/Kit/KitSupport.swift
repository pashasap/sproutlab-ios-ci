import SwiftUI
import Core

/// A tap target drawn from a Core `KitTapTarget`: size, identifier and command all come from Core.
struct KitTargetButton<Content: View>: View {
    let target: KitTapTarget
    let label: String
    let action: (KitCommand) -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button { action(target.command) } label: {
            content()
                .frame(minWidth: KitMetrics.minTarget, minHeight: KitMetrics.minTarget)
                .frame(width: target.width, height: target.height)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.ink.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(target.identifier)
    }
}

extension KitTapTarget {
    /// Spoken label: the Core label for the command, followed by the token when there is one.
    func label(for actions: [KitAccessibilityAction], _ language: Language) -> String {
        let match = actions.first { $0.command == command }
        let words = match.map { TextTable.string($0.labelKey, language) } ?? ""
        return [words, subject ?? ""].filter { !$0.isEmpty }.joined(separator: " ")
    }
}

extension View {
    /// Exposes every Core accessibility action to VoiceOver and Switch Control.
    func kitActions(_ actions: [KitAccessibilityAction], language: Language,
                    perform: @escaping (KitAccessibilityAction) -> Void) -> some View {
        accessibilityActions {
            ForEach(actions.indices, id: \.self) { index in
                let action = actions[index]
                Button([TextTable.string(action.labelKey, language), action.subject ?? ""]
                    .filter { !$0.isEmpty }.joined(separator: " ")) { perform(action) }
            }
        }
    }

    /// Speaks the newest Core announcement whenever one is appended.
    func kitAnnounce(_ announcements: [KitAnnouncement], language: Language) -> some View {
        onChange(of: announcements.count) {
            guard let last = announcements.last else { return }
            let text = [TextTable.string(last.key, language), last.subject ?? ""]
                .filter { !$0.isEmpty }.joined(separator: " ")
            AccessibilityNotification.Announcement(text).post()
        }
    }
}
