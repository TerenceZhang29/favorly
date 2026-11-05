import SwiftUI

/// The mockup's back link: a chevron and the tab's name in the brand color ("‹ Nearby"), in place of the
/// system back button. Swipe-to-go-back keeps working.
struct GroveBackLinkModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.currentTab) private var currentTab

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        dismiss()
                    } label: {
                        // A plain icon and text: iOS 26 draws only the icon of a Label in the bar.
                        HStack(spacing: Theme.Spacing.small) {
                            Image(systemName: "chevron.left")
                                .fontWeight(.semibold)
                            Text(currentTab?.title ?? "Back")
                        }
                        .textStyle(.bodyStrong)
                        .foregroundStyle(Theme.Colors.brand)
                        .fixedSize()
                    }
                    .accessibilityLabel("Back to \(currentTab?.title ?? "the previous screen")")
                    .accessibilityIdentifier("nav.back")
                }
            }
        #if canImport(UIKit)
            .background(SwipeBackEnabler().frame(width: 0, height: 0))
        #endif
    }
}
