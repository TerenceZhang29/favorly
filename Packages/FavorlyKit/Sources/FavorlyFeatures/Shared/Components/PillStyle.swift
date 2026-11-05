import SwiftUI

/// A small rounded action, such as "Message" or "Mark completed" on a My Activity card: olive for the main
/// action, the soft tint for the others.
struct PillStyle: ViewModifier {
    let isPrimary: Bool

    func body(content: Content) -> some View {
        content
            .textStyle(.metaStrong)
            .foregroundStyle(isPrimary ? Theme.Colors.onBrand : Theme.Colors.onTint)
            .padding(.horizontal, Theme.Spacing.large + Theme.Spacing.small / 2)
            .frame(minHeight: Theme.pillHeight)
            .background(isPrimary ? Theme.Colors.brand : Theme.Colors.tint, in: Capsule())
            .contentShape(Capsule())
            .fixedSize()
    }
}
