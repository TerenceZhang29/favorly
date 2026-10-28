import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Foundation
import Testing

@MainActor
struct KindnessEnvironmentTests {
    let world = TestWorld()

    @Test func everyDemoUsersScoreIsAvailableThroughTheEnvironment() async throws {
        let kindness = world.environment.kindness
        #expect(try await kindness.kindnessSummary(for: DemoUsers.bea.id).lifetimePoints == 90)
        #expect(try await kindness.kindnessSummary(for: DemoUsers.chen.id).lifetimePoints == 18)
        #expect(try await kindness.kindnessSummary(for: DemoUsers.dana.id).lifetimePoints == 0)
        #expect(try await kindness.kindnessSummary(for: DemoUsers.alex.id).lifetimePoints == 0)
    }

    @Test func reviewsAreAvailableThroughTheEnvironment() async throws {
        let reviews = world.environment.reviews
        #expect(try await reviews.reviews(about: DemoUsers.bea.id).count == 4)
        #expect(try await reviews.review(for: TestWorld.seedID(12)) == nil)
    }

    @Test func aFavorCompletedThroughTheRequestRepositoryCountsTowardTheScore() async throws {
        let environment = world.environment
        _ = try await environment.repository.claim(TestWorld.eggsID, by: DemoUsers.bea.id)
        _ = try await environment.repository.complete(TestWorld.eggsID, by: DemoUsers.chen.id)
        #expect(try await environment.kindness.kindnessSummary(for: DemoUsers.bea.id).availablePoints == 100)
        #expect(try await environment.kindness.redeemGiftCard(by: DemoUsers.bea.id).code == "FAVORLY-0001")
    }

    @Test func previewScoresComeFromItsFixedData() async throws {
        let bea = UserID(rawValue: "preview-bea")
        let completed = HelpRequest(
            id: RequestID(rawValue: UUID()),
            title: "Need a cup of sugar",
            details: "",
            category: .ingredient,
            location: TaggedLocation(point: GeoPoint(latitude: 40.7553, longitude: -73.9562), label: "Cornell Tech"),
            requesterID: UserID(rawValue: "preview-alex"),
            helperID: bea,
            status: .completed,
            createdAt: TestWorld.now,
            claimedAt: TestWorld.now
        )
        let review = Review(
            id: ReviewID(rawValue: UUID()),
            requestID: completed.id,
            reviewerID: completed.requesterID,
            revieweeID: bea,
            rating: 5,
            comment: "Thanks!",
            createdAt: TestWorld.now
        )
        let preview = PreviewRequestRepository(requests: [completed], reviews: [review])

        #expect(try await preview.kindnessSummary(for: bea).lifetimePoints == 20)
        #expect(try await preview.reviews(about: bea) == [review])
        #expect(try await preview.review(for: completed.id) == review)
        #expect(try await preview.redemptions(by: bea).isEmpty)
        await #expect(throws: FavorlyError.notAllowed) {
            try await preview.redeemGiftCard(by: bea)
        }
    }
}
