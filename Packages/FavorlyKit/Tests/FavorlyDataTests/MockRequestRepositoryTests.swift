import FavorlyCore
import FavorlyData
import Foundation
import Testing

struct MockRequestRepositoryTests {
    static let now = Date(timeIntervalSince1970: 1_000_000)
    static let cornellTech = LocationPresets.cornellTech.location.point
    static let eggsID = RequestID(rawValue: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)))
    static let ladderID = RequestID(rawValue: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6)))

    let alex = DemoUsers.alex.id
    let bea = DemoUsers.bea.id
    let chen = DemoUsers.chen.id
    let dana = DemoUsers.dana.id

    let repository = MockRequestRepository(
        seed: { DemoRequests.all(now: now) },
        artificialDelay: .zero,
        now: { now }
    )

    private var draft: NewRequestDraft {
        NewRequestDraft(
            title: "  Need a cup of rice ",
            details: "",
            category: .ingredient,
            location: LocationPresets.cornellTech.location
        )
    }

    private func nearby(miles: Double, around point: GeoPoint = cornellTech) async throws -> [NearbyRequest] {
        try await repository.nearby(around: point, radiusMeters: Distance.meters(fromMiles: miles))
    }

    // MARK: nearby

    @Test func nearbyFiltersByRadius() async throws {
        #expect(try await nearby(miles: 0.25).count == 3)
        #expect(try await nearby(miles: 1).count == 7)
        #expect(try await nearby(miles: 3).count == 8)
        #expect(try await nearby(miles: 1, around: LocationPresets.ithaca.location.point).isEmpty)
    }

    @Test func nearbyReturnsOnlyOpenRequests() async throws {
        let results = try await nearby(miles: 3)
        #expect(results.allSatisfy { $0.request.status == .open })
        #expect(!results.contains { $0.id == Self.ladderID })
    }

    @Test func nearbySortsByDistanceAscending() async throws {
        let results = try await nearby(miles: 3)
        #expect(results.map(\.distanceMeters) == results.map(\.distanceMeters).sorted())
        #expect(results.first?.id == Self.eggsID)
        #expect(results.allSatisfy { $0.distanceMeters <= Distance.meters(fromMiles: 3) })
    }

    @Test func nearbyBreaksDistanceTiesByNewestFirst() async throws {
        let older = try await repository.create(draft, by: alex)
        let clock = TestClock(Self.now)
        let later = MockRequestRepository(seed: { [older] }, artificialDelay: .zero, now: { clock.advance(by: 60) })
        let newer = try await later.create(draft, by: bea)

        let results = try await later.nearby(around: Self.cornellTech, radiusMeters: 10)
        #expect(results.map(\.id) == [newer.id, older.id])
    }

    // MARK: lookups

    @Test func requestByIDReturnsItOrThrowsNotFound() async throws {
        #expect(try await repository.request(id: Self.eggsID).title == "Need 2 eggs for a cake")
        await #expect(throws: FavorlyError.notFound) {
            try await repository.request(id: RequestID(rawValue: UUID()))
        }
    }

    @Test func requestsPostedByAUserAreNewestFirst() async throws {
        #expect(try await repository.requests(postedBy: alex).isEmpty)
        let posted = try await repository.requests(postedBy: chen)
        #expect(posted.count == 6)
        #expect(posted.allSatisfy { $0.requesterID == chen })
        #expect(posted.map(\.createdAt) == posted.map(\.createdAt).sorted(by: >))
    }

    @Test func requestsClaimedByAUserIncludeFinishedOnes() async throws {
        #expect(try await repository.requests(claimedBy: alex).isEmpty)
        #expect(try await repository.requests(claimedBy: chen).map(\.status) == [.claimed, .completed])
        #expect(try await repository.requests(claimedBy: bea).map(\.status) == Array(repeating: .completed, count: 5))
    }

    // MARK: create

    @Test func createAssignsRequesterOpenStatusAndCurrentTime() async throws {
        let created = try await repository.create(draft, by: alex)
        #expect(created.requesterID == alex)
        #expect(created.status == .open)
        #expect(created.createdAt == Self.now)
        #expect(created.helperID == nil)
        #expect(created.title == "Need a cup of rice")
        #expect(created.location == LocationPresets.cornellTech.location)
        #expect(try await repository.request(id: created.id) == created)
        #expect(try await nearby(miles: 1).first?.id == created.id)
    }

    @Test func createRejectsAnInvalidDraft() async throws {
        var invalid = draft
        invalid.title = "ab"
        await #expect(throws: FavorlyError.validation("Title must be at least 3 characters.")) {
            try await repository.create(invalid, by: alex)
        }
        #expect(try await repository.requests(postedBy: alex).isEmpty)
    }

    // MARK: claim

    @Test func claimSetsHelperClaimedAtAndStatus() async throws {
        let claimed = try await repository.claim(Self.eggsID, by: bea)
        #expect(claimed.helperID == bea)
        #expect(claimed.claimedAt == Self.now)
        #expect(claimed.status == .claimed)
        #expect(try await repository.request(id: Self.eggsID) == claimed)
        #expect(try await !nearby(miles: 1).contains { $0.id == Self.eggsID })
        #expect(try await repository.requests(claimedBy: bea).contains(claimed))
    }

    @Test func doubleClaimThrowsAlreadyClaimed() async throws {
        _ = try await repository.claim(Self.eggsID, by: bea)
        await #expect(throws: FavorlyError.alreadyClaimed) {
            try await repository.claim(Self.eggsID, by: dana)
        }
        #expect(try await repository.request(id: Self.eggsID).helperID == bea)
    }

    @Test func onlyOneOfManyConcurrentClaimsSucceeds() async {
        let repository = repository
        let claimers = [alex, bea, dana]
        let successes = await withTaskGroup(of: Bool.self) { group in
            for user in claimers {
                group.addTask { await (try? repository.claim(Self.eggsID, by: user)) != nil }
            }
            return await group.reduce(into: 0) { count, succeeded in count += succeeded ? 1 : 0 }
        }
        #expect(successes == 1)
    }

    @Test func claimingYourOwnRequestThrows() async {
        await #expect(throws: FavorlyError.cannotClaimOwnRequest) {
            try await repository.claim(Self.eggsID, by: chen)
        }
    }

    @Test func claimingAMissingRequestThrowsNotFound() async {
        await #expect(throws: FavorlyError.notFound) {
            try await repository.claim(RequestID(rawValue: UUID()), by: bea)
        }
    }

    // MARK: cancel

    @Test func requesterCanCancel() async throws {
        #expect(try await repository.cancel(Self.eggsID, by: chen).status == .cancelled)
        #expect(try await repository.cancel(Self.ladderID, by: dana).status == .cancelled)
    }

    @Test func cancelByAnyoneElseThrowsNotAllowed() async throws {
        await #expect(throws: FavorlyError.notAllowed) {
            try await repository.cancel(Self.ladderID, by: chen)
        }
        #expect(try await repository.request(id: Self.ladderID).status == .claimed)
    }

    @Test func cancellingTwiceThrowsInvalidTransition() async throws {
        _ = try await repository.cancel(Self.eggsID, by: chen)
        await #expect(throws: FavorlyError.invalidTransition(from: .cancelled, to: .cancelled)) {
            try await repository.cancel(Self.eggsID, by: chen)
        }
    }

    // MARK: complete

    @Test func requesterCanCompleteAClaimedRequest() async throws {
        #expect(try await repository.complete(Self.ladderID, by: dana).status == .completed)
    }

    @Test func completeByTheHelperOrAStrangerThrowsNotAllowed() async throws {
        await #expect(throws: FavorlyError.notAllowed) {
            try await repository.complete(Self.ladderID, by: chen)
        }
        await #expect(throws: FavorlyError.notAllowed) {
            try await repository.complete(Self.ladderID, by: alex)
        }
        #expect(try await repository.request(id: Self.ladderID).status == .claimed)
    }

    @Test func completingAnOpenRequestThrowsInvalidTransition() async {
        await #expect(throws: FavorlyError.invalidTransition(from: .open, to: .completed)) {
            try await repository.complete(Self.eggsID, by: chen)
        }
    }

    // MARK: changes and reset

    @Test(.timeLimit(.minutes(1)))
    func changesEmitsAfterEveryKindOfWrite() async throws {
        let writes: [@Sendable (MockRequestRepository) async throws -> Void] = [
            { _ = try await $0.create(draft, by: alex) },
            { _ = try await $0.claim(Self.eggsID, by: bea) },
            { _ = try await $0.complete(Self.eggsID, by: chen) },
            { _ = try await $0.cancel(Self.ladderID, by: dana) },
            { await $0.reset() },
        ]
        for write in writes {
            var iterator = repository.changes().makeAsyncIterator()
            try await write(repository)
            #expect(await iterator.next() != nil)
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func changesReachesEverySubscriber() async throws {
        var first = repository.changes().makeAsyncIterator()
        var second = repository.changes().makeAsyncIterator()
        _ = try await repository.claim(Self.eggsID, by: bea)
        #expect(await first.next() != nil)
        #expect(await second.next() != nil)
    }

    @Test func failedWritesAndReadsDoNotEmit() async throws {
        let stream = repository.changes()
        _ = try? await repository.claim(Self.eggsID, by: chen)
        _ = try await nearby(miles: 1)

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

    @Test func resetRestoresTheSeedData() async throws {
        _ = try await repository.create(draft, by: alex)
        _ = try await repository.claim(Self.eggsID, by: bea)

        await repository.reset()

        #expect(try await repository.requests(postedBy: alex).isEmpty)
        #expect(try await repository.request(id: Self.eggsID).status == .open)
        #expect(try await nearby(miles: 1).count == 7)
    }

    @Test func artificialDelayIsApplied() async throws {
        let slow = MockRequestRepository(artificialDelay: .milliseconds(100))
        let started = ContinuousClock.now
        _ = try await slow.request(id: Self.eggsID)
        #expect(ContinuousClock.now - started >= .milliseconds(100))
    }
}
