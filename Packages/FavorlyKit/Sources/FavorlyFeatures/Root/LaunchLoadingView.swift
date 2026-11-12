import SwiftUI

/// Shown while a saved session is restored at launch: the logo, a lime bar sliding along a track, and a caption.
/// It is usually on screen for under a second, so the bar moves calmly; with Reduce Motion it stands still.
struct LaunchLoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweeping = false

    var body: some View {
        VStack(spacing: Theme.Launch.logoGap) {
            FavorlyLogo()
                .frame(width: Theme.Launch.logoWidth)
            VStack(spacing: Theme.Launch.captionGap) {
                track
                Text("Loading your neighborhood…")
                    .textStyle(.metaStrong)
                    .foregroundStyle(Theme.Colors.inkMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GroveBackground().ignoresSafeArea())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("root.restoring")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: Theme.Launch.sweep).repeatForever(autoreverses: false)) {
                sweeping = true
            }
        }
    }

    private var track: some View {
        let barWidth = Theme.Launch.trackWidth * Theme.Launch.barShare
        let start = -barWidth
        let end = Theme.Launch.trackWidth
        let resting = (Theme.Launch.trackWidth - barWidth) / 2
        return Capsule()
            .fill(Theme.Colors.surfaceBorder)
            .frame(width: Theme.Launch.trackWidth, height: Theme.Launch.trackHeight)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(Theme.Colors.lime)
                    .frame(width: barWidth, height: Theme.Launch.trackHeight)
                    .offset(x: reduceMotion ? resting : (sweeping ? end : start))
            }
            .clipShape(Capsule())
            .accessibilityHidden(true)
    }
}

#Preview {
    LightAndDarkPreview { LaunchLoadingView() }
}
