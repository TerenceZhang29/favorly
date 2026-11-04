import SwiftUI

/// Shows the same content in light and dark mode, one above the other, for component previews.
struct LightAndDarkPreview<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            ForEach([ColorScheme.light, .dark], id: \.self) { colorScheme in
                VStack(spacing: Theme.Spacing.large) {
                    content
                }
                .padding(Theme.Spacing.section)
                .frame(maxWidth: .infinity)
                .background(GroveBackground())
                .environment(\.colorScheme, colorScheme)
            }
        }
    }
}
