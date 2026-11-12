import FavorlyCore
import FavorlyData
import Foundation
import Testing

struct MockChatRepositoryTests {
    static let start = Date(timeIntervalSince1970: 1_000_000)
    static let eggsID = DemoRequests.id(1)
    static let ladderID = DemoRequests.id(6)

    let alex = DemoUsers.alex.id
    let bea = DemoUsers.bea.id
    let chen = DemoUsers.chen.id
    let dana = DemoUsers.dana.id

    let clock = TestClock(Self.start)
    let repository: MockRequestRepository

    init() {
        let clock = clock
        repository = MockRequestRepository(
            seed: { DemoRequests.all(now: Self.start) },
            reviewSeed: { DemoReviews.all(now: Self.start) },
            artificialDelay: .zero,
            now: { clock.advance(by: 60) }
        )
    }

    @Test func aClaimedRequestStartsWithAnEmptyThread() async throws {
        #expect(try await repository.messages(for: Self.ladderID, as: dana).isEmpty)
        #expect(try await repository.messages(for: Self.ladderID, as: chen).isEmpty)
    }

    @Test func theInboxGetsEveryReadableThreadAndSkipsTheRest() async throws {
        _ = try await repository.send("On my way", in: Self.ladderID, by: chen)
        _ = try await repository.send("Thanks!", in: Self.ladderID, by: dana)
        let messages = try await repository.messages(inRequests: [Self.ladderID, Self.eggsID], as: dana)
        #expect(messages.map(\.text) == ["On my way", "Thanks!"])
        #expect(try await repository.messages(inRequests: [Self.ladderID], as: alex).isEmpty)
        #expect(try await repository.messages(inRequests: [], as: dana).isEmpty)
    }

    @Test func thereIsNoThreadBeforePickUp() async {
        await #expect(throws: FavorlyError.notAllowed) {
            try await repository.messages(for: Self.eggsID, as: chen)
        }
        await #expect(throws: FavorlyError.notAllowed) {
            try await repository.send("Hello", in: Self.eggsID, by: chen)
        }
    }

    @Test func aNonParticipantGetsNotAllowed() async {
        await #expect(throws: FavorlyError.notAllowed) {
            try await repository.messages(for: Self.ladderID, as: alex)
        }
        await #expect(throws: FavorlyError.notAllowed) {
            try await repository.send("Hello", in: Self.ladderID, by: bea)
        }
    }

    @Test func anUnknownRequestThrowsNotFound() async {
        await #expect(throws: FavorlyError.notFound) {
            try await repository.messages(for: RequestID(rawValue: UUID()), as: chen)
        }
        await #expect(throws: FavorlyError.notFound) {
            try await repository.send("Hello", in: RequestID(rawValue: UUID()), by: chen)
        }
    }

    @Test func messagesAreTrimmedAndListedOldestFirst() async throws {
        let first = try await repository.send("  On my way ", in: Self.ladderID, by: chen)
        let second = try await repository.send("Thanks!", in: Self.ladderID, by: dana)

        #expect(first.text == "On my way")
        #expect(first.senderID == chen)
        #expect(first.requestID == Self.ladderID)
        #expect(first.sentAt < second.sentAt)
        let thread = try await repository.messages(for: Self.ladderID, as: dana)
        #expect(thread == [first, second])
    }

    @Test func threadsAreKeptApart() async throws {
        _ = try await repository.claim(Self.eggsID, by: bea)
        _ = try await repository.send("Eggs coming", in: Self.eggsID, by: bea)
        _ = try await repository.send("Ladder coming", in: Self.ladderID, by: chen)
        #expect(try await repository.messages(for: Self.eggsID, as: chen).map(\.text) == ["Eggs coming"])
        #expect(try await repository.messages(for: Self.ladderID, as: chen).map(\.text) == ["Ladder coming"])
    }

    @Test func textLimitsAreEnforced() async throws {
        await #expect(throws: FavorlyError.validation("Message can't be empty.")) {
            try await repository.send("  ", in: Self.ladderID, by: chen)
        }
        await #expect(throws: FavorlyError.validation("Message must be 500 characters or fewer.")) {
            try await repository.send(String(repeating: "a", count: 501), in: Self.ladderID, by: chen)
        }
        #expect(try await repository.messages(for: Self.ladderID, as: chen).isEmpty)
    }

    @Test func sendingClosesWhenTheRequestIsCompletedButTheThreadStaysReadable() async throws {
        _ = try await repository.send("On my way", in: Self.ladderID, by: chen)
        _ = try await repository.complete(Self.ladderID, by: dana)
        await #expect(throws: FavorlyError.notAllowed) {
            try await repository.send("One more thing", in: Self.ladderID, by: dana)
        }
        #expect(try await repository.messages(for: Self.ladderID, as: dana).map(\.text) == ["On my way"])
    }

    @Test(.timeLimit(.minutes(1)))
    func changesEmitsOnSend() async throws {
        var iterator = repository.changes().makeAsyncIterator()
        _ = try await repository.send("On my way", in: Self.ladderID, by: chen)
        #expect(await iterator.next() != nil)
    }

    @Test func resetRemovesEveryMessage() async throws {
        _ = try await repository.send("On my way", in: Self.ladderID, by: chen)
        await repository.reset()
        #expect(try await repository.messages(for: Self.ladderID, as: chen).isEmpty)
    }
}
