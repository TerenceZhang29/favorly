import Foundation

public enum RequestRules {
    /// Status moves only `open → claimed → completed`, plus `open → cancelled` and `claimed → cancelled`.
    public static func canTransition(from: RequestStatus, to: RequestStatus) -> Bool {
        switch (from, to) {
        case (.open, .claimed), (.claimed, .completed), (.open, .cancelled), (.claimed, .cancelled):
            true
        default:
            false
        }
    }

    public static func validateClaim(request: HelpRequest, by user: UserID) throws {
        guard request.requesterID != user else { throw FavorlyError.cannotClaimOwnRequest }
        guard request.status != .claimed else { throw FavorlyError.alreadyClaimed }
        try validateTransition(from: request.status, to: .claimed)
    }

    /// Only the requester can cancel.
    public static func validateCancel(request: HelpRequest, by user: UserID) throws {
        guard request.requesterID == user else { throw FavorlyError.notAllowed }
        try validateTransition(from: request.status, to: .cancelled)
    }

    /// Only the requester can mark a request completed, so a helper cannot award themselves points (rule 15).
    public static func validateComplete(request: HelpRequest, by user: UserID) throws {
        guard request.requesterID == user else { throw FavorlyError.notAllowed }
        try validateTransition(from: request.status, to: .completed)
    }

    /// A picked-up request completes on its own this long after pick-up if the requester never confirms (rule 15).
    public static let autoCompleteInterval: TimeInterval = 7 * 24 * 60 * 60

    /// When a picked-up request completes on its own, or nil for a request that is not picked up.
    public static func autoCompleteDate(of request: HelpRequest) -> Date? {
        guard request.status == .claimed, let claimedAt = request.claimedAt else { return nil }
        return claimedAt.addingTimeInterval(autoCompleteInterval)
    }

    /// True for a picked-up request whose pick-up was `autoCompleteInterval` or more before `now`.
    public static func isAutoCompleteDue(_ request: HelpRequest, now: Date) -> Bool {
        guard let date = autoCompleteDate(of: request) else { return false }
        return date <= now
    }

    private static func validateTransition(from: RequestStatus, to: RequestStatus) throws {
        guard canTransition(from: from, to: to) else {
            throw FavorlyError.invalidTransition(from: from, to: to)
        }
    }
}
