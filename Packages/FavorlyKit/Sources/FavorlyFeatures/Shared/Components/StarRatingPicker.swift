import FavorlyCore
import SwiftUI

/// Five large star buttons. Tapping the third star sets the rating to 3. Each star is its own button for
/// VoiceOver ("3 stars", selected when it is the rating) and for UI tests (`review.star.3`).
struct StarRatingPicker: View {
    @Binding var rating: Int
    var maximum = ReviewRules.ratingRange.upperBound
    @ScaledMetric private var scaledSide = Theme.controlHeight

    /// Grows with the text, but never so far that five stars no longer fit across a phone.
    private var side: CGFloat { min(scaledSide, Theme.IconSize.starMax) }

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            ForEach(1 ... maximum, id: \.self) { star in
                let isFilled = star <= rating
                Button {
                    rating = star
                } label: {
                    Image(systemName: isFilled ? "star.fill" : "star")
                        .font(.system(size: side * Theme.IconSize.symbolScale, weight: .medium))
                        .foregroundStyle(isFilled ? Theme.Colors.star : Theme.Colors.starEmpty)
                        .frame(width: side, height: side)
                        .background(
                            isFilled ? Theme.Colors.tint : Theme.Colors.surface,
                            in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(star == 1 ? "1 star" : "\(star) stars")
                .accessibilityAddTraits(star == rating ? .isSelected : [])
                .accessibilityIdentifier("review.star.\(star)")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    LightAndDarkPreview {
        StarRatingPicker(rating: .constant(4))
        StarRatingPicker(rating: .constant(0))
    }
}
