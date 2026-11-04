import SwiftUI

/// The screen background: Grove's off-white, or deep moss with a soft glow near the top in dark mode.
/// The glow is decoration: hidden from VoiceOver and left out when Reduce Transparency is on.
struct GroveBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle().fill(Theme.Colors.background)
            if colorScheme == .dark, !reduceTransparency {
                Circle()
                    .fill(Theme.Colors.glow)
                    .frame(width: Theme.IconSize.glow, height: Theme.IconSize.glow)
                    .blur(radius: Theme.glowBlur)
                    .opacity(Theme.glowOpacity)
                    .offset(x: Theme.IconSize.glow / 3, y: -Theme.IconSize.glow / 3)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview {
    LightAndDarkPreview {
        GroveBackground()
            .frame(height: 200)
    }
}
