import FavorlyCore
import FavorlyData
import Foundation
import Testing

/// Rule 15: a picked-up request completes on its own 7 days after pick-up.
struct MockAutoCompleteTests {
    static let start = Date(timeIntervalSince1970: 1_000_000)
    static let eggsID = DemoRequests.id(1)
    /// Dana's ladder request, picked up by Chen 45 minutes before `start`.
    static let ladderID = DemoRequests.id(6)

    let chen = DemoUsers.chen.id
    let dana = DemoUsers.dana.id

    let clock = AdjustableClock(Self.start)
    let repository: MockRequestRepository

    init() {
        let clock = clock
        repository = MockRequestRepository(
            seed: { DemoRequests.all(now: clock.now) },
            reviewSeed: { DemoReviews.all(now: clock.now) },
            artificialDelay: .zero,
            now: { clock.now }
        )
    }

    /// Moves the clock to `offset` seconds after the ladder's pick-up plus 7 days.
    private func moveToAutoComplete(plus offset: TimeInterval) async throws {
        let claimedAt = try #require(try await repository.request(id: Self.ladderID).claimedAt)
        let due = claimedAt.addingTimeInterval(RequestRules.autoCompleteInterval)
        clock.moveForward(by: due.timeIntervalSince(clock.now) + offset)
    }

    @Test func notCompletedOneSecondBeforeSevenDays() async throws {
        try await moveToAutoComplete(plus: -1)
        #expect(try await repository.request(id: Self.ladderID).status == .claimed)
    }

    @Test func completedAtSevenDays() async throws {
        try await moveToAutoComplete(plus: 0)
        #expect(try await repository.request(id: Self.ladderID).status == .completed)
        #expect(try await repository.requests(claimedBy: chen).first { $0.id == Self.ladderID }?.status == .completed)
    }

    @Test func anAutoCompletedFavorEarnsThePointsAndCanBeReviewed() async throws {
        #expect(try await repository.kindnessSummary(for: chen).lifetimePoints == 18)
        try await moveToAutoComplete(plus: 60)
        #expect(try await repository.kindnessSummary(for: chen).lifetimePoints == 28)

        let review = try await repository.submitReview(
            NewReviewDraft(rating: 5, comment: "Thanks"), for: Self.ladderID, by: dana
        )
        #expect(review.revieweeID == chen)
    }

    @Test(.timeLimit(.minutes(1)))
    func autoCompletingEmitsAChange() async throws {
        try await moveToAutoComplete(plus: -1)
        var iterator = repository.changes().makeAsyncIterator()
        clock.moveForward(by: 1)
        _ = try await repository.request(id: Self.eggsID)
        #expect(await iterator.next() != nil)
    }

    @Test func openAndCancelledRequestsNeverAutoComplete() async throws {
        _ = try await repository.cancel(Self.ladderID, by: dana)
        clock.moveForward(by: 30 * 24 * 60 * 60)
        #expect(try await repository.request(id: Self.ladderID).status == .cancelled)
        #expect(try await repository.request(id: Self.eggsID).status == .open)
    }

    @Test func resetRestoresThePickedUpRequest() async throws {
        try await moveToAutoComplete(plus: 0)
        #expect(try await repository.request(id: Self.ladderID).status == .completed)
        await repository.reset()
        #expect(try await repository.request(id: Self.ladderID).status == .claimed)
    }
}
