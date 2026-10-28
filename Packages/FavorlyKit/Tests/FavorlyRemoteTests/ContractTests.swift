import FavorlyCore
import Foundation
import Testing

/// The same checks against the mock and the local backend, so the two behave alike. When they disagree, the
/// server is right and the mock is fixed.
@MainActor
struct ContractTests {
    // MARK: Posting and nearby

    @Test(arguments: ContractBackend.enabled)
    func aPostedRequestShowsUpNearbyForOthers(backend: ContractBackend) async throws {
        let world = ContractWorld(backend)
        let alex = try await world.signUp("Alex")
        let bea = try await world.signUp("Bea")

        let rice = try await alex.requests.create(world.draft("  Need a cup of rice "), by: alex.id)
        #expect(rice.title == "Need a cup of rice")
        #expect(rice.status == .open)
        #expect(rice.requesterID == alex.id)
        _ = try await alex.requests.create(world.draft("Five km away", at: world.north(by: 5000)), by: alex.id)

        let nearby = try await bea.requests.nearby(around: world.here.point, radiusMeters: 1000)
        #expect(nearby.map(\.request.title) == ["Need a cup of rice"])
        #expect(try #require(nearby.first).distanceMeters < 200)
        let wider = try await bea.requests.nearby(around: world.here.point, radiusMeters: 10000)
        #expect(wider.map(\.request.title) == ["Need a cup of rice", "Five km away"])
    }

    @Test(arguments: ContractBackend.enabled)
    func anInvalidTitleIsRefusedWithTheSameMessage(backend: ContractBackend) async throws {
        let world = ContractWorld(backend)
        let alex = try await world.signUp("Alex")
        await #expect(throws: FavorlyError.validation("Title must be at least 3 characters.")) {
            try await alex.requests.create(world.draft("Hi"), by: alex.id)
        }
    }

    @Test(arguments: ContractBackend.enabled)
    func yourOwnListsAreNewestFirst(backend: ContractBackend) async throws {
        let world = ContractWorld(backend)
        let alex = try await world.signUp("Alex")
        let bea = try await world.signUp("Bea")
        let first = try await alex.requests.create(world.draft("First"), by: alex.id)
        let second = try await alex.requests.create(world.draft("Second"), by: alex.id)
        _ = try await bea.requests.claim(first.id, by: bea.id)

        #expect(try await alex.requests.requests(postedBy: alex.id).map(\.id) == [second.id, first.id])
        #expect(try await bea.requests.requests(claimedBy: bea.id).map(\.id) == [first.id])
        #expect(try await bea.requests.request(id: first.id).helperID == bea.id)
    }

    // MARK: Pick up, cancel, complete

    @Test(arguments: ContractBackend.enabled)
    func pickUpRules(backend: ContractBackend) async throws {
        let world = ContractWorld(backend)
        let alex = try await world.signUp("Alex")
        let bea = try await world.signUp("Bea")
        let chen = try await world.signUp("Chen")
        let eggs = try await alex.requests.create(world.draft("Need 2 eggs"), by: alex.id)

        await #expect(throws: FavorlyError.cannotClaimOwnRequest) {
            try await alex.requests.claim(eggs.id, by: alex.id)
        }
        let claimed = try await bea.requests.claim(eggs.id, by: bea.id)
        #expect(claimed.status == .claimed)
        #expect(claimed.helperID == bea.id)
        #expect(claimed.claimedAt != nil)
        await #expect(throws: FavorlyError.alreadyClaimed) {
            try await chen.requests.claim(eggs.id, by: chen.id)
        }
        await #expect(throws: FavorlyError.notFound) {
            try await chen.requests.claim(RequestID(rawValue: UUID()), by: chen.id)
        }
    }

    @Test(arguments: ContractBackend.enabled)
    func onlyTheRequesterCancelsOrCompletes(backend: ContractBackend) async throws {
        let world = ContractWorld(backend)
        let alex = try await world.signUp("Alex")
        let bea = try await world.signUp("Bea")
        let eggs = try await alex.requests.create(world.draft("Need 2 eggs"), by: alex.id)

        await #expect(throws: FavorlyError.invalidTransition(from: .open, to: .completed)) {
            try await alex.requests.complete(eggs.id, by: alex.id)
        }
        _ = try await bea.requests.claim(eggs.id, by: bea.id)
        await #expect(throws: FavorlyError.notAllowed) {
            try await bea.requests.complete(eggs.id, by: bea.id)
        }
        await #expect(throws: FavorlyError.notAllowed) {
            try await bea.requests.cancel(eggs.id, by: bea.id)
        }
        #expect(try await alex.requests.complete(eggs.id, by: alex.id).status == .completed)
        await #expect(throws: FavorlyError.invalidTransition(from: .completed, to: .cancelled)) {
            try await alex.requests.cancel(eggs.id, by: alex.id)
        }

        let rice = try await alex.requests.create(world.draft("Need rice"), by: alex.id)
        #expect(try await alex.requests.cancel(rice.id, by: alex.id).status == .cancelled)
    }

    // MARK: Chat

    @Test(arguments: ContractBackend.enabled)
    func theRequesterAndHelperChatUntilCompletion(backend: ContractBackend) async throws {
        let world = ContractWorld(backend)
        let alex = try await world.signUp("Alex")
        let bea = try await world.signUp("Bea")
        let eggs = try await alex.requests.create(world.draft("Need 2 eggs"), by: alex.id)
        _ = try await bea.requests.claim(eggs.id, by: bea.id)

        let first = try await bea.chat.send("  On my way ", in: eggs.id, by: bea.id)
        #expect(first.text == "On my way")
        #expect(first.senderID == bea.id)
        _ = try await alex.chat.send("Thank you!", in: eggs.id, by: alex.id)
        #expect(try await alex.chat.messages(for: eggs.id, as: alex.id).map(\.text) == ["On my way", "Thank you!"])
        await #expect(throws: FavorlyError.validation("Message can't be empty.")) {
            try await bea.chat.send("   ", in: eggs.id, by: bea.id)
        }

        _ = try await alex.requests.complete(eggs.id, by: alex.id)
        await #expect(throws: FavorlyError.notAllowed) {
            try await bea.chat.send("Late", in: eggs.id, by: bea.id)
        }
    }

    // MARK: Reviews and Kindness

    @Test(arguments: ContractBackend.enabled)
    func aReviewedFavorEarnsTheHelperPoints(backend: ContractBackend) async throws {
        let world = ContractWorld(backend)
        let alex = try await world.signUp("Alex")
        let bea = try await world.signUp("Bea")
        let eggs = try await alex.requests.create(world.draft("Need 2 eggs"), by: alex.id)
        _ = try await bea.requests.claim(eggs.id, by: bea.id)

        #expect(try await bea.kindness.kindnessSummary(for: bea.id).lifetimePoints == 0)
        await #expect(throws: FavorlyError.notAllowed) {
            try await alex.reviews.submitReview(NewReviewDraft(rating: 5, comment: ""), for: eggs.id, by: alex.id)
        }
        _ = try await alex.requests.complete(eggs.id, by: alex.id)
        #expect(try await bea.kindness.kindnessSummary(for: bea.id).lifetimePoints == 10)

        await #expect(throws: FavorlyError.notAllowed) {
            try await bea.reviews.submitReview(NewReviewDraft(rating: 5, comment: ""), for: eggs.id, by: bea.id)
        }
        let review = try await alex.reviews.submitReview(
            NewReviewDraft(rating: 5, comment: " Fast and friendly "), for: eggs.id, by: alex.id
        )
        #expect(review.comment == "Fast and friendly")
        #expect(review.revieweeID == bea.id)
        await #expect(throws: FavorlyError.alreadyReviewed) {
            try await alex.reviews.submitReview(NewReviewDraft(rating: 4, comment: ""), for: eggs.id, by: alex.id)
        }

        let summary = try await alex.kindness.kindnessSummary(for: bea.id)
        #expect(summary.lifetimePoints == 20)
        #expect(summary.completedFavors == 1)
        #expect(summary.averageRating == 5)
        #expect(try await alex.reviews.reviews(about: bea.id).map(\.id) == [review.id])
        #expect(try await bea.reviews.review(for: eggs.id)?.rating == 5)
    }

    // MARK: Changes

    @Test(.timeLimit(.minutes(1)), arguments: ContractBackend.enabled)
    func aWriteAnnouncesAChange(backend: ContractBackend) async throws {
        let world = ContractWorld(backend)
        let alex = try await world.signUp("Alex")
        var changes = alex.requests.changes().makeAsyncIterator()
        _ = try await alex.requests.create(world.draft("Need rice"), by: alex.id)
        #expect(await changes.next() != nil)
    }
}
