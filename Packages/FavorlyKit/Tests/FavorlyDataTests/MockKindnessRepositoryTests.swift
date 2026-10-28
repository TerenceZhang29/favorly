import FavorlyCore
import FavorlyData
import Foundation
import Testing

struct MockKindnessRepositoryTests {
    static let now = Date(timeIntervalSince1970: 1_000_000)
    static let eggsID = DemoRequests.id(1)
    static let ladderID = DemoRequests.id(6)

    let alex = DemoUsers.alex.id
    let bea = DemoUsers.bea.id
    let chen = DemoUsers.chen.id
    let dana = DemoUsers.dana.id

    let repository = MockRequestRepository(
        seed: { DemoRequests.all(now: now) },
        reviewSeed: { DemoReviews.all(now: now) },
        artificialDelay: .zero,
        now: { now }
    )

    /// Bea picks up Chen's eggs request and Chen completes it: 90 + 10 = 100 points.
    private func beaCompletesAFavor() async throws {
        _ = try await repository.claim(Self.eggsID, by: bea)
        _ = try await repository.complete(Self.eggsID, by: chen)
    }

    /// Alex posts `count` requests, `helper` picks up each one and Alex completes it: 10 points apiece.
    private func complete(favors count: Int, by helper: UserID) async throws {
        let draft = NewRequestDraft(
            title: "Need a cup of rice",
            details: "",
            category: .ingredient,
            location: LocationPresets.cornellTech.location
        )
        for _ in 0 ..< count {
            let request = try await repository.create(draft, by: alex)
            _ = try await repository.claim(request.id, by: helper)
            _ = try await repository.complete(request.id, by: alex)
        }
    }

    // MARK: Seed scores

    @Test func seedScoresMatchThePlan() async throws {
        #expect(try await repository.kindnessSummary(for: bea) == KindnessSummary(
            completedFavors: 5,
            reviewCount: 4,
            averageRating: 5,
            lifetimePoints: 90,
            redeemedPoints: 0
        ))
        #expect(try await repository.kindnessSummary(for: chen) == KindnessSummary(
            completedFavors: 1,
            reviewCount: 1,
            averageRating: 4,
            lifetimePoints: 18,
            redeemedPoints: 0
        ))
        #expect(try await repository.kindnessSummary(for: dana).lifetimePoints == 0)
        #expect(try await repository.kindnessSummary(for: alex).lifetimePoints == 0)
        #expect(try await repository.kindnessSummary(for: alex).averageRating == nil)
    }

    @Test func aClaimedRequestEarnsNothingUntilItIsCompleted() async throws {
        #expect(try await repository.kindnessSummary(for: chen).lifetimePoints == 18)
        _ = try await repository.complete(Self.ladderID, by: dana)
        #expect(try await repository.kindnessSummary(for: chen).lifetimePoints == 28)
    }

    @Test func aCancelledPickUpEarnsNothing() async throws {
        _ = try await repository.cancel(Self.ladderID, by: dana)
        #expect(try await repository.kindnessSummary(for: chen).completedFavors == 1)
    }

    @Test func onlyTheHelperEarnsPoints() async throws {
        try await beaCompletesAFavor()
        #expect(try await repository.kindnessSummary(for: bea).lifetimePoints == 100)
        #expect(try await repository.kindnessSummary(for: chen).lifetimePoints == 18)
    }

    // MARK: Redeem

    @Test func redeemAt90PointsThrowsNotEnoughPoints() async throws {
        await #expect(throws: FavorlyError.notEnoughPoints) {
            try await repository.redeemGiftCard(by: bea)
        }
        #expect(try await repository.redemptions(by: bea).isEmpty)
    }

    @Test func redeemAt100PointsSpendsThemAndKeepsTheLifetimeScore() async throws {
        try await beaCompletesAFavor()

        let redemption = try await repository.redeemGiftCard(by: bea)
        #expect(redemption.userID == bea)
        #expect(redemption.points == 100)
        #expect(redemption.code == "FAVORLY-0001")
        #expect(redemption.createdAt == Self.now)

        let summary = try await repository.kindnessSummary(for: bea)
        #expect(summary.lifetimePoints == 100)
        #expect(summary.redeemedPoints == 100)
        #expect(summary.availablePoints == 0)
        #expect(try await repository.redemptions(by: bea) == [redemption])
    }

    @Test func aSecondRedeemRightAwayThrowsNotEnoughPoints() async throws {
        try await beaCompletesAFavor()
        _ = try await repository.redeemGiftCard(by: bea)
        await #expect(throws: FavorlyError.notEnoughPoints) {
            try await repository.redeemGiftCard(by: bea)
        }
    }

    @Test func twoRedemptionsInARowGetCountingCodesNewestFirst() async throws {
        try await complete(favors: 11, by: bea)
        #expect(try await repository.kindnessSummary(for: bea).availablePoints == 200)

        let first = try await repository.redeemGiftCard(by: bea)
        let second = try await repository.redeemGiftCard(by: bea)
        #expect(first.code == "FAVORLY-0001")
        #expect(second.code == "FAVORLY-0002")
        #expect(try await repository.redemptions(by: bea) == [second, first])
        #expect(try await repository.kindnessSummary(for: bea).availablePoints == 0)
        #expect(try await repository.kindnessSummary(for: bea).lifetimePoints == 200)
    }

    @Test func codesCountAcrossUsersAndRedemptionsArePerUser() async throws {
        try await beaCompletesAFavor()
        let beas = try await repository.redeemGiftCard(by: bea)
        try await complete(favors: 9, by: chen)
        let chens = try await repository.redeemGiftCard(by: chen)

        #expect(beas.code == "FAVORLY-0001")
        #expect(chens.code == "FAVORLY-0002")
        #expect(try await repository.redemptions(by: bea) == [beas])
        #expect(try await repository.redemptions(by: chen) == [chens])
        #expect(try await repository.redemptions(by: alex).isEmpty)
    }

    // MARK: changes and reset

    @Test(.timeLimit(.minutes(1)))
    func changesEmitsOnRedeem() async throws {
        try await beaCompletesAFavor()
        var iterator = repository.changes().makeAsyncIterator()
        _ = try await repository.redeemGiftCard(by: bea)
        #expect(await iterator.next() != nil)
    }

    @Test func aFailedRedeemDoesNotEmit() async throws {
        let stream = repository.changes()
        _ = try? await repository.redeemGiftCard(by: bea)

        let received = Task {
            var count = 0
            for await _ in stream {
                count += 1
            }
            return count
        }
        try await Task.sleep(for: .milliseconds(50))
        received.cancel()
        #expect(await received.value == 0)
    }

    @Test func resetClearsRedemptionsAndRestartsTheCodes() async throws {
        try await beaCompletesAFavor()
        _ = try await repository.redeemGiftCard(by: bea)

        await repository.reset()

        #expect(try await repository.redemptions(by: bea).isEmpty)
        #expect(try await repository.kindnessSummary(for: bea).availablePoints == 90)
        try await beaCompletesAFavor()
        #expect(try await repository.redeemGiftCard(by: bea).code == "FAVORLY-0001")
    }
}
