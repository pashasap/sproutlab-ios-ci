import SwiftUI
import Core

/// One calm celebration; static when Reduce Motion is on.
struct SummaryView: View {
    let app: AppViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var settled = false

    private var plan: CelebrationPlan? { app.celebrationPlan(reduceMotion: reduceMotion) }
    private var stars: Int { plan?.stars ?? app.round?.summary?.stars ?? 0 }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            starRow
            Text(plan?.text(app.language) ?? TextTable.string("summary.title", app.language))
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.ink)
            Button { app.leaveSummary() } label: {
                HStack(spacing: 8) {
                    Image(systemName: ChromeCatalog.summaryBackSymbolName)
                        .accessibilityHidden(true)
                    Text(TextTable.string("summary.back", app.language))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel(TextTable.string("a11y.back", app.language))
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .onAppear { settle() }
    }

    private var starRow: some View {
        HStack(spacing: 12) {
            ForEach(0..<max(stars, 1), id: \.self) { _ in
                Image(systemName: ChromeCatalog.symbolName(for: .star))
                    .font(.system(size: 56))
                    .foregroundStyle(Palette.star)
            }
        }
        .scaleEffect(settled ? 1 : 0.6)
        .opacity(settled ? 1 : 0.4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AccessibilityText.roundResult(stars: stars, language: app.language))
    }

    private func settle() {
        if let plan, plan.motion == .gentle {
            withAnimation(.easeOut(duration: plan.duration)) { settled = true }
        } else {
            settled = true
        }
    }
}
