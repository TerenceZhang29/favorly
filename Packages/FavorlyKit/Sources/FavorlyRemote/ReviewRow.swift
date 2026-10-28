import FavorlyCore
import Foundation

struct ReviewRow: Decodable, Sendable {
    let id: UUID
    let requestID: UUID
    let reviewerID: UUID
    let revieweeID: UUID
    let rating: Int
    let comment: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, rating, comment
        case requestID = "request_id"
        case reviewerID = "reviewer_id"
        case revieweeID = "reviewee_id"
        case createdAt = "created_at"
    }

    func model() -> Review {
        Review(
            id: ReviewID(rawValue: id),
            requestID: RequestID(rawValue: requestID),
            reviewerID: UserID(remote: reviewerID),
            revieweeID: UserID(remote: revieweeID),
            rating: rating,
            comment: comment,
            createdAt: createdAt
        )
    }
}
