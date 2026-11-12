import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

/// The full-name Favorly logo on a transparent background: dark lettering in light mode, white in dark mode.
struct FavorlyLogo: View {
    @Environment(\.colorScheme) private var colorScheme

    /// The image file's name in this module's bundle, without the scale suffix.
    nonisolated static func resourceName(dark: Bool) -> String {
        dark ? "FavorlyLogoDark" : "FavorlyLogo"
    }

    var body: some View {
        logo
            .accessibilityLabel(Text("Favorly"))
            .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder private var logo: some View {
        #if canImport(UIKit)
            if let image = UIImage(
                named: Self.resourceName(dark: colorScheme == .dark),
                in: .module,
                compatibleWith: nil
            ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                wordmark
            }
        #else
            wordmark
        #endif
    }

    /// Stands in if the image can't be loaded.
    private var wordmark: some View {
        Text("Favorly")
            .textStyle(.largeTitle)
            .foregroundStyle(Theme.Colors.ink)
    }
}
