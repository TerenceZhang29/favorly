import SwiftUI

/// The count on a tab's icon, such as unread messages: dark text on the spark color, widening for two digits.
struct TabBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .textStyle(.badge)
            .foregroundStyle(Theme.Colors.onSpark)
            .padding(.horizontal, Theme.Spacing.small)
            .frame(minWidth: Theme.IconSize.badge, minHeight: Theme.IconSize.badge)
            .background(Theme.Colors.spark, in: Capsule())
            .fixedSize()
            .offset(x: Theme.IconSize.badge * 0.7, y: -Theme.IconSize.badge / 3)
            .accessibilityHidden(true)
    }
}
