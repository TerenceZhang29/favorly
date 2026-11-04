import SwiftUI

extension View {
    /// Draws this list row as a Grove card. Use it in a `.plain` list.
    func cardRow(isHighlighted: Bool = false) -> some View {
        modifier(CardRowModifier(isHighlighted: isHighlighted))
    }
}
