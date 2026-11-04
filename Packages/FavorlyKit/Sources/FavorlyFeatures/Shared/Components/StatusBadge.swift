import SwiftUI

/// A short piece of text in a capsule, such as "Open" or "Claimed by Bea". Long text wraps; it is never cut off.
struct StatusBadge: View {
    let text: String
    let colors: BadgeColors

    var body: some View {
        Text(text)
            .textStyle(.badge)
            .foregroundStyle(colors.text)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Theme.Spacing.medium + Theme.Spacing.small / 2)
            .padding(.vertical, Theme.Spacing.small)
            .background(colors.fill, in: Capsule())
            .overlay {
                if let outline = colors.outline {
                    Capsule().strokeBorder(outline, lineWidth: Theme.borderWidth)
                }
            }
    }
}

#Preview {
    LightAndDarkPreview {
        StatusBadge(text: "Open", colors: .lime)
        StatusBadge(text: "Claimed by Bea", colors: .tint)
        StatusBadge(text: "Completed", colors: .quiet)
        StatusBadge(text: "Cancelled", colors: .outline)
    }
}
