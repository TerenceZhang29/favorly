import FavorlyCore
import SwiftUI

/// A review on a profile: its stars, the comment, and who wrote it when.
struct ReviewRow: View {
    let rating: Int
    let comment: String
    let reviewerName: String
    /// "Oct 7".
    let dateText: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            StarRating(rating: rating)
            if !comment.isEmpty {
                Text(comment)
                    .textStyle(.body)
                    .foregroundStyle(Theme.Colors.ink)
            }
            Text("\(reviewerName) · \(dateText)")
                .textStyle(.meta)
                .foregroundStyle(Theme.Colors.inkMuted)
        }
        .padding(.vertical, Theme.Spacing.small)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
    }

    /// "5 out of 5 stars from Dana, Oct 7: Fast and friendly".
    private var spokenLabel: String {
        let heading = "\(rating) out of \(ReviewRules.ratingRange.upperBound) stars from \(reviewerName), \(dateText)"
        return comment.isEmpty ? heading : "\(heading): \(comment)"
    }
}

#Preview {
    LightAndDarkPreview {
        ReviewRow(rating: 5, comment: "Fast and friendly", reviewerName: "Dana", dateText: "Oct 7")
        ReviewRow(rating: 4, comment: "", reviewerName: "Chen", dateText: "Oct 8")
    }
}
