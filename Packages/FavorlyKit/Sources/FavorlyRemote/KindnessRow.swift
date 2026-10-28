import FavorlyCore
import Foundation

/// A row of `kindness_summary`.
struct KindnessRow: Decodable, Sendable {
    let completedFavors: Int
    let reviewCount: Int
    let averageRating: Double?
    let lifetimePoints: Int

    enum CodingKeys: String, CodingKey {
        case completedFavors = "completed_favors"
        case reviewCount = "review_count"
        case averageRating = "average_rating"
        case lifetimePoints = "lifetime_points"
    }

    /// Gift cards are gone in 1.0, so nothing is ever redeemed.
    func model() -> KindnessSummary {
        KindnessSummary(
            completedFavors: completedFavors,
            reviewCount: reviewCount,
            averageRating: averageRating,
            lifetimePoints: lifetimePoints,
            redeemedPoints: 0
        )
    }
}
