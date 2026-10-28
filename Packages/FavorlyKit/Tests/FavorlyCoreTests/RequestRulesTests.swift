import FavorlyCore
import Foundation
import Testing

struct RequestRulesTests {
    static let allStatuses: [RequestStatus] = [.open, .claimed, .completed, .cancelled]
    static let terminalStatuses: [RequestStatus] = [.completed, .cancelled]

    @Test(arguments: allStatuses, allStatuses)
    func transitionIsAllowedOnlyAlongThePlannedPaths(from: RequestStatus, to: RequestStatus) {
        let allowed: [[RequestStatus]] = [
            [.open, .claimed],
            [.claimed, .completed],
            [.open, .cancelled],
            [.claimed, .cancelled],
        ]
        #expect(RequestRules.canTransition(from: from, to: to) == allowed.contains([from, to]))
    }

    // MARK: Claim

    @Test func anotherUserCanClaimAnOpenRequest() throws {
        try RequestRules.validateClaim(request: .fixture(), by: .helper)
    }

    @Test func requesterCannotClaimTheirOwnRequest() {
        #expect(throws: FavorlyError.cannotClaimOwnRequest) {
            try RequestRules.validateClaim(request: .fixture(), by: .requester)
        }
    }

    @Test func secondClaimThrowsAlreadyClaimed() {
        #expect(throws: FavorlyError.alreadyClaimed) {
            try RequestRules.validateClaim(request: .fixture(status: .claimed), by: .stranger)
        }
    }

    @Test(arguments: terminalStatuses)
    func finishedRequestCannotBeClaimed(status: RequestStatus) {
        #expect(throws: FavorlyError.invalidTransition(from: status, to: .claimed)) {
            try RequestRules.validateClaim(request: .fixture(status: status), by: .stranger)
        }
    }

    // MARK: Cancel

    @Test(arguments: [RequestStatus.open, .claimed])
    func requesterCanCancelAnOpenOrClaimedRequest(status: RequestStatus) throws {
        try RequestRules.validateCancel(request: .fixture(status: status), by: .requester)
    }

    @Test(arguments: [UserID.helper, .stranger])
    func onlyTheRequesterCanCancel(user: UserID) {
        #expect(throws: FavorlyError.notAllowed) {
            try RequestRules.validateCancel(request: .fixture(status: .claimed), by: user)
        }
    }

    @Test(arguments: terminalStatuses)
    func finishedRequestCannotBeCancelled(status: RequestStatus) {
        #expect(throws: FavorlyError.invalidTransition(from: status, to: .cancelled)) {
            try RequestRules.validateCancel(request: .fixture(status: status), by: .requester)
        }
    }

    // MARK: Complete

    @Test func requesterCanCompleteAClaimedRequest() throws {
        try RequestRules.validateComplete(request: .fixture(status: .claimed), by: .requester)
    }

    @Test(arguments: [UserID.helper, .stranger])
    func onlyTheRequesterCanComplete(user: UserID) {
        #expect(throws: FavorlyError.notAllowed) {
            try RequestRules.validateComplete(request: .fixture(status: .claimed), by: user)
        }
    }

    @Test(arguments: [RequestStatus.open, .completed, .cancelled])
    func onlyAClaimedRequestCanBeCompleted(status: RequestStatus) {
        #expect(throws: FavorlyError.invalidTransition(from: status, to: .completed)) {
            try RequestRules.validateComplete(request: .fixture(status: status), by: .requester)
        }
    }

    // MARK: Auto-complete

    /// The fixture is picked up at 60 seconds after the epoch.
    static let pickedUpAt = Date(timeIntervalSince1970: 60)

    @Test func autoCompleteDateIsSevenDaysAfterPickUp() {
        #expect(RequestRules.autoCompleteDate(of: .fixture(status: .claimed))
            == Self.pickedUpAt.addingTimeInterval(7 * 24 * 60 * 60))
    }

    @Test func notDueOneSecondBeforeSevenDays() {
        let now = Self.pickedUpAt.addingTimeInterval(RequestRules.autoCompleteInterval - 1)
        #expect(!RequestRules.isAutoCompleteDue(.fixture(status: .claimed), now: now))
    }

    @Test func dueAtExactlySevenDays() {
        let now = Self.pickedUpAt.addingTimeInterval(RequestRules.autoCompleteInterval)
        #expect(RequestRules.isAutoCompleteDue(.fixture(status: .claimed), now: now))
    }

    @Test(arguments: [RequestStatus.open, .completed, .cancelled])
    func onlyAPickedUpRequestAutoCompletes(status: RequestStatus) {
        let muchLater = Self.pickedUpAt.addingTimeInterval(30 * 24 * 60 * 60)
        #expect(RequestRules.autoCompleteDate(of: .fixture(status: status)) == nil)
        #expect(!RequestRules.isAutoCompleteDue(.fixture(status: status), now: muchLater))
    }
}
