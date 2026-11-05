import FavorlyCore
import Observation

/// The requester's review of the helper, for one completed request.
@MainActor
@Observable
final class ReviewFormViewModel {
    let requestID: RequestID
    /// 0 until the user picks a star.
    var rating = 0
    var comment = ""
    private(set) var isSubmitting = false
    /// Why the last submit failed.
    private(set) var submitError: String?

    @ObservationIgnored private let environment: AppEnvironment

    init(requestID: RequestID, environment: AppEnvironment) {
        self.requestID = requestID
        self.environment = environment
    }

    // MARK: Live validation

    /// Submit stays disabled until a rating is chosen and the comment fits.
    var canSubmit: Bool {
        !isSubmitting && validationMessage == nil
    }

    /// What is wrong with the comment, once it is too long. A missing rating only disables Submit.
    var commentMessage: String? {
        guard comment.count > ReviewRules.maxCommentLength else { return nil }
        return validationMessage
    }

    /// "12 / 300".
    /// What the helper earns for this favor with the chosen rating, as in the Grove mockup: "Bea earns +18
    /// Kindness points for this favor", or, before a rating, "Bea earns 10 points, plus 2 per star".
    func pointsText(for helperName: String) -> String {
        guard rating > 0 else {
            let base = KindnessRules.pointsPerFavor
            return "\(helperName) earns \(base) points, plus \(KindnessRules.pointsPerStar) per star"
        }
        let points = KindnessRules.pointsPerFavor + KindnessRules.pointsPerStar * rating
        return "\(helperName) earns +\(points) Kindness points for this favor"
    }

    var commentCountText: String {
        "\(comment.count) / \(ReviewRules.maxCommentLength)"
    }

    // MARK: Submitting

    /// Submits the review as the signed-in user. Returns it on success, so the sheet can close.
    func submit() async -> Review? {
        guard canSubmit else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        submitError = nil

        do {
            return try await environment.reviews.submitReview(
                NewReviewDraft(rating: rating, comment: comment),
                for: requestID,
                by: environment.session.currentUser.id
            )
        } catch {
            submitError = ErrorMessage.text(for: error)
            return nil
        }
    }

    // MARK: Helpers

    private var validationMessage: String? {
        do {
            try ReviewRules.validate(NewReviewDraft(rating: rating, comment: comment))
            return nil
        } catch {
            return ErrorMessage.text(for: error)
        }
    }
}
