import FavorlyCore
import Foundation

extension MockRequestRepository: KindnessRepository {
    public func kindnessSummary(for user: UserID) async throws -> KindnessSummary {
        try await beginOperation()
        return summary(for: user)
    }

    public func redemptions(by user: UserID) async throws -> [Redemption] {
        try await beginOperation()
        return redemptions.filter { $0.userID == user }.reversed()
    }

    public func redeemGiftCard(by user: UserID) async throws -> Redemption {
        try await beginOperation()
        try KindnessRules.validateRedeem(summary(for: user))
        let redemption = Redemption(
            id: RedemptionID(rawValue: UUID()),
            userID: user,
            points: KindnessRules.giftCardCost,
            code: KindnessRules.rewardCode(number: redemptions.count + 1),
            createdAt: now()
        )
        redemptions.append(redemption)
        broadcaster.send()
        return redemption
    }

    /// The user's score from the current state, in one actor turn.
    private func summary(for user: UserID) -> KindnessSummary {
        KindnessRules.summary(
            completedAsHelper: requests.values.filter { $0.helperID == user },
            reviews: reviews.filter { $0.revieweeID == user },
            redemptions: redemptions.filter { $0.userID == user }
        )
    }
}
