import FavorlyCore
import FavorlyData
import Foundation
import Testing

struct MockModerationTests {
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

    @Test func aReportIsStoredWithItsTrimmedNote() async throws {
        try await repository.report(.request(Self.eggsID), reason: .spam, note: "  Looks fake ", by: bea)
        #expect(await repository.submittedReports()
            == [MockReport(target: .request(Self.eggsID), reason: .spam, note: "Looks fake", reporterID: bea)])
    }

    @Test func reportingSomethingUnknownOrYourselfIsRefused() async {
        await #expect(throws: FavorlyError.notFound) {
            try await repository.report(.request(RequestID(rawValue: UUID())), reason: .spam, note: "", by: bea)
        }
        await #expect(throws: FavorlyError.notFound) {
            try await repository.report(.message(MessageID(rawValue: UUID())), reason: .spam, note: "", by: bea)
        }
        await #expect(throws: FavorlyError.notAllowed) {
            try await repository.report(.user(bea), reason: .unsafe, note: "", by: bea)
        }
    }

    @Test func blockedPeopleAreListedNewestFirstAndCanBeUnblocked() async throws {
        try await repository.block(chen, by: bea)
        try await repository.block(dana, by: bea)
        try await repository.block(chen, by: bea)
        #expect(try await repository.blockedUsers(of: bea) == [DemoUsers.dana, DemoUsers.chen])
        #expect(try await repository.blockedUsers(of: chen).isEmpty)

        try await repository.unblock(dana, by: bea)
        #expect(try await repository.blockedUsers(of: bea) == [DemoUsers.chen])
        await #expect(throws: FavorlyError.notAllowed) {
            try await repository.block(bea, by: bea)
        }
    }

    @Test func aBlockStopsPickUpsInBothDirections() async throws {
        try await repository.block(chen, by: bea)
        await #expect(throws: FavorlyError.blocked) {
            try await repository.claim(Self.eggsID, by: bea) // Chen's request
        }
        try await repository.unblock(chen, by: bea)
        try await repository.block(bea, by: chen)
        await #expect(throws: FavorlyError.blocked) {
            try await repository.claim(Self.eggsID, by: bea)
        }
    }

    @Test func aBlockSilencesAnExistingThread() async throws {
        _ = try await repository.send("On my way", in: Self.ladderID, by: chen)
        try await repository.block(chen, by: dana)
        await #expect(throws: FavorlyError.blocked) {
            try await repository.send("Hello?", in: Self.ladderID, by: chen)
        }
    }

    @Test func resetForgetsReportsAndBlocks() async throws {
        try await repository.block(chen, by: bea)
        try await repository.report(.user(chen), reason: .other, note: "", by: bea)
        await repository.reset()
        #expect(try await repository.blockedUsers(of: bea).isEmpty)
        #expect(await repository.submittedReports().isEmpty)
    }
}
