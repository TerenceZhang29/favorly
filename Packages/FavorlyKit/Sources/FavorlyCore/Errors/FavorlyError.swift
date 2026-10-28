import Foundation

public enum FavorlyError: Error, Equatable, Sendable {
    case notFound
    case alreadyClaimed
    case cannotClaimOwnRequest
    /// For example, cancelling someone else's request.
    case notAllowed
    case invalidTransition(from: RequestStatus, to: RequestStatus)
    /// Carries a user-facing message.
    case validation(String)
    case locationUnavailable
    /// The user said no to location, or it is off for Favorly in Settings.
    case locationPermissionDenied
    /// The requester already reviewed this request.
    case alreadyReviewed
    /// Fewer available Kindness points than a gift card costs.
    case notEnoughPoints
    /// No session, or the profile is not finished. The server says so when a session has expired.
    case notSignedIn
    /// Over one of the server's limits on posting or messaging.
    case rateLimited
    /// One of the two people blocked the other.
    case blocked
    /// The server could not be reached.
    case network
}
