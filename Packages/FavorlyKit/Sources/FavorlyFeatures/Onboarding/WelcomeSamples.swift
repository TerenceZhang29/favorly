import SwiftUI

/// Decoration on Welcome: two sample request cards and a points chip, tilted a little, to show what the app
/// is for. They hold no data and are hidden from VoiceOver.
struct WelcomeSamples: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            sample(symbol: "carrot", title: "Two eggs for a cake", meta: "0.1 mi · Priya")
                .rotationEffect(.degrees(-2))
            sample(symbol: "car", title: "Jump start, please", meta: "0.4 mi · Dev")
                .rotationEffect(.degrees(2))
                .padding(.leading, Theme.Spacing.section * 2)
            Label("+18 Kindness points", systemImage: "heart.fill")
                .textStyle(.bodyStrong)
                .foregroundStyle(Theme.Colors.onLime)
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.vertical, Theme.Spacing.medium)
                .background(Theme.Colors.lime, in: Capsule())
                .rotationEffect(.degrees(-2))
                .padding(.leading, Theme.Spacing.section)
        }
        .accessibilityHidden(true)
    }

    private func sample(symbol: String, title: String, meta: String) -> some View {
        HStack(spacing: Theme.Spacing.large) {
            CategoryIcon(systemImage: symbol)
            VStack(alignment: .leading, spacing: Theme.Spacing.small / 2) {
                Text(title)
                    .textStyle(.bodyStrong)
                    .foregroundStyle(Theme.Colors.ink)
                Text(meta)
                    .textStyle(.meta)
                    .foregroundStyle(Theme.Colors.inkMuted)
            }
        }
        .padding(Theme.Spacing.card)
        .background(CardBackground())
        .fixedSize()
    }
}

#Preview {
    LightAndDarkPreview {
        WelcomeSamples()
    }
}
