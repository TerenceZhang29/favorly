import SwiftUI

/// A Grove card: a rounded surface with a thin outline and, in light mode, a soft shadow.
/// A highlighted card, such as a request just posted, is filled with the olive tint instead.
struct CardBackground: View {
    var isHighlighted = false

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .fill(isHighlighted ? Theme.Colors.tint : Theme.Colors.surface)
            .strokeBorder(Theme.Colors.surfaceBorder, lineWidth: Theme.borderWidth)
            .groveShadow(Theme.Shadow.card)
    }
}

#Preview {
    LightAndDarkPreview {
        CardBackground()
            .frame(height: 80)
        CardBackground(isHighlighted: true)
            .frame(height: 80)
    }
}
