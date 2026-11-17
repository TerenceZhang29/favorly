import FavorlyCore
import FavorlyData
import Foundation
import Testing

struct MockRequestViewsTests {
    static let now = Date(timeIntervalSince1970: 1_000_000)
    /// Chen's open request.
    static let eggsID = DemoRequests.id(1)

    let alex = DemoUsers.alex.id
    let bea = DemoUsers.bea.id
    let chen = DemoUsers.chen.id

    let repository = MockRequestRepository(
        seed: { DemoRequests.all(now: now) },
        reviewSeed: { DemoReviews.all(now: now) },
        artificialDelay: .zero,
        now: { now }
    )

    @Test func eachPersonCountsOnce() async throws {
        try await repository.recordView(of: Self.eggsID, by: bea)
        try await repository.recordView(of: Self.eggsID, by: bea)
        try await repository.recordView(of: Self.eggsID, by: alex)
        #expect(await repository.viewerCount(of: Self.eggsID) == 2)
    }

    @Test func theRequestersOwnViewDoesNotCount() async throws {
        try await repository.recordView(of: Self.eggsID, by: chen)
        #expect(await repository.viewerCount(of: Self.eggsID) == 0)
    }

    @Test func cancelledUnknownAndBlockedAreSkippedWithoutAnError() async throws {
        try await repository.recordView(of: RequestID(rawValue: UUID()), by: bea)

        try await repository.block(chen, by: alex)
        try await repository.recordView(of: Self.eggsID, by: alex)
        #expect(await repository.viewerCount(of: Self.eggsID) == 0)

        _ = try await repository.cancel(Self.eggsID, by: chen)
        try await repository.recordView(of: Self.eggsID, by: bea)
        #expect(await repository.viewerCount(of: Self.eggsID) == 0)
    }

    @Test func resetForgetsViews() async throws {
        try await repository.recordView(of: Self.eggsID, by: bea)
        await repository.reset()
        #expect(await repository.viewerCount(of: Self.eggsID) == 0)
    }
}
