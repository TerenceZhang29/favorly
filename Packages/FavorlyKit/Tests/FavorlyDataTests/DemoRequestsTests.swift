import FavorlyCore
import FavorlyData
import Foundation
import Testing

struct DemoRequestsTests {
    let now = Date(timeIntervalSince1970: 1_000_000)
    var requests: [HelpRequest] { DemoRequests.all(now: now) }
    /// Seeds 1–12, the Phase 1 set. Seeds 13–17 are the completed history added in Phase 3.
    var phaseOne: [HelpRequest] { Array(requests.prefix(12)) }
    var history: [HelpRequest] { Array(requests.dropFirst(12)) }

    private func miles(_ request: HelpRequest) -> Double {
        Distance.meters(from: LocationPresets.cornellTech.location.point, to: request.location.point)
            / Distance.metersPerMile
    }

    @Test func seedHasSeventeenRequestsWithStableUniqueIDs() {
        #expect(requests.count == 17)
        #expect(Set(requests.map(\.id)).count == 17)
        #expect(requests.map(\.id) == (1 ... 17).map { DemoRequests.id($0) })
        #expect(requests.map(\.id) == DemoRequests.all(now: now.addingTimeInterval(3600)).map(\.id))
    }

    @Test func noneBelongToAlexAndEveryRequesterIsADemoUser() {
        let demoUserIDs = Set(DemoUsers.all.map(\.id))
        #expect(requests.allSatisfy { $0.requesterID != DemoUsers.alex.id })
        #expect(requests.allSatisfy { demoUserIDs.contains($0.requesterID) })
    }

    @Test func mostAreOpenWithOneClaimedAndOneCompleted() {
        #expect(phaseOne.count(where: { $0.status == .open }) == 10)
        #expect(phaseOne.count(where: { $0.status == .claimed }) == 1)
        #expect(phaseOne.count(where: { $0.status == .completed }) == 1)
        #expect(requests.allSatisfy { ($0.status == .open) == ($0.helperID == nil) })
        #expect(requests.allSatisfy { ($0.helperID == nil) == ($0.claimedAt == nil) })
    }

    @Test func distancesFromCornellTechAreSpreadAsPlanned() {
        #expect(phaseOne.count(where: { miles($0) <= 0.5 }) == 6)
        #expect(phaseOne.count(where: { miles($0) > 0.5 && miles($0) <= 1.5 }) == 3)
        #expect(phaseOne.count(where: { miles($0) > 3 }) == 3)
    }

    @Test func timestampsAreInThePastRelativeToNow() {
        #expect(requests.allSatisfy { $0.createdAt < now })
        #expect(requests.allSatisfy { ($0.claimedAt ?? now) > $0.createdAt })
    }

    @Test func historyIsCompletedDaysAgoWithoutAlex() {
        let alex = DemoUsers.alex.id
        #expect(history.count == 5)
        #expect(history.allSatisfy { $0.status == .completed })
        #expect(history.allSatisfy { $0.createdAt <= now.addingTimeInterval(-2 * 24 * 60 * 60) })
        #expect(history.allSatisfy { $0.requesterID != alex && $0.helperID != alex })
        #expect(history.count(where: { $0.helperID == DemoUsers.bea.id }) == 4)
        #expect(history.count(where: { $0.helperID == DemoUsers.chen.id }) == 1)
    }
}
