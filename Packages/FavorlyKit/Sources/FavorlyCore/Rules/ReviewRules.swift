import Foundation

/// Who can review a favor, and what a review may contain.
public enum ReviewRules {
    public static let ratingRange = 1 ... 5
    public static let maxCommentLength = 300

    /// Only the requester can review, only a completed request with a helper, and only once.
    public static func validateReviewer(request: HelpRequest, by user: UserID, existing: Review?) throws {
        guard request.requesterID == user, request.status == .completed, request.helperID != nil else {
            throw FavorlyError.notAllowed
        }
        guard existing == nil else { throw FavorlyError.alreadyReviewed }
    }

    public static func canReview(request: HelpRequest, by user: UserID, existing: Review?) -> Bool {
        (try? validateReviewer(request: request, by: user, existing: existing)) != nil
    }

    /// Checks the rating and comment limits and returns the draft with the comment trimmed.
    @discardableResult
    public static func validate(_ draft: NewReviewDraft) throws -> NewReviewDraft {
        var normalized = draft
        normalized.comment = draft.comment.trimmingCharacters(in: .whitespacesAndNewlines)

        guard ratingRange.contains(normalized.rating) else {
            throw FavorlyError.validation(
                "Choose a rating from \(ratingRange.lowerBound) to \(ratingRange.upperBound) stars."
            )
        }
        guard normalized.comment.count <= maxCommentLength else {
            throw FavorlyError.validation("Comment must be \(maxCommentLength) characters or fewer.")
        }
        try ContentFilter.validate(normalized.comment)
        return normalized
    }
}
