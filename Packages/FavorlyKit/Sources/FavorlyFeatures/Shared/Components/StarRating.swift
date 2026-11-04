import FavorlyCore
import SwiftUI

/// A read-only row of stars, such as 4 of 5 filled. VoiceOver reads "4 out of 5 stars".
struct StarRating: View {
    let rating: Int
    var maximum = ReviewRules.ratingRange.upperBound

    var body: some View {
        HStack(spacing: Theme.Spacing.small / 2) {
            ForEach(1 ... maximum, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundStyle(star <= rating ? Theme.Colors.star : Theme.Colors.starEmpty)
            }
        }
        .textStyle(.meta)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rating) out of \(maximum) stars")
    }
}

#Preview {
    LightAndDarkPreview {
        StarRating(rating: 5)
        StarRating(rating: 4)
        StarRating(rating: 0)
    }
}
