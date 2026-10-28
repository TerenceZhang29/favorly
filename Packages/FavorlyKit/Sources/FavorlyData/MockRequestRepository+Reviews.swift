import FavorlyCore
import Foundation

extension MockRequestRepository: ReviewRepository {
    public func reviews(about user: UserID) async throws -> [Review] {
        try await beginOperation()
        return reviews
            .filter { $0.revieweeID == user }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Throws `notFound` for an unknown request; returns `nil` while it has no review.
    public func review(for request: RequestID) async throws -> Review? {
        try await beginOperation()
        guard requests[request] != nil else { throw FavorlyError.notFound }
        return reviews.first { $0.requestID == request }
    }

    /// Validates and stores the review in one actor turn, so two submissions cannot both succeed.
    public func submitReview(_ draft: NewReviewDraft, for request: RequestID, by user: UserID) async throws -> Review {
        try await beginOperation()
        guard let helpRequest = requests[request] else { throw FavorlyError.notFound }
        let existing = reviews.first { $0.requestID == request }
        try ReviewRules.validateReviewer(request: helpRequest, by: user, existing: existing)
        let draft = try ReviewRules.validate(draft)
        guard let helperID = helpRequest.helperID else { throw FavorlyError.notAllowed }
        let review = Review(
            id: ReviewID(rawValue: UUID()),
            requestID: request,
            reviewerID: user,
            revieweeID: helperID,
            rating: draft.rating,
            comment: draft.comment,
            createdAt: now()
        )
        reviews.append(review)
        broadcaster.send()
        return review
    }
}
