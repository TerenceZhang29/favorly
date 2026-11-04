import SwiftUI

/// Draws a list row as its own Grove card, with a gap to the next one. The row stays a real list row, so
/// tapping, VoiceOver and the identifiers work as before.
struct CardRowModifier: ViewModifier {
    let isHighlighted: Bool

    func body(content: Content) -> some View {
        content
            .padding(.vertical, Theme.Spacing.small)
            .listRowInsets(EdgeInsets(
                top: Theme.Spacing.cardGap + Theme.Spacing.card,
                leading: Theme.Spacing.screen + Theme.Spacing.card,
                bottom: Theme.Spacing.cardGap + Theme.Spacing.card,
                trailing: Theme.Spacing.screen + Theme.Spacing.card
            ))
            .listRowBackground(
                CardBackground(isHighlighted: isHighlighted)
                    .padding(.horizontal, Theme.Spacing.screen)
                    .padding(.vertical, Theme.Spacing.cardGap)
            )
            .listRowSeparator(.hidden)
    }
}
