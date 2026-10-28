import FavorlyCore

enum ErrorMessage {
    /// The sentence shown to the user when `error` reaches a screen.
    static func text(for error: any Error) -> String {
        guard let error = error as? FavorlyError else { return "Something went wrong. Please try again." }
        return switch error {
        case .notFound: "This request is no longer available."
        case .alreadyClaimed: "Someone else already picked this up."
        case .cannotClaimOwnRequest: "You can't pick up your own request."
        case .notAllowed: "You're not allowed to do that."
        case .invalidTransition: "This request can't be changed that way anymore."
        case let .validation(message): message
        case .locationUnavailable: "Your location isn't available right now."
        case .locationPermissionDenied:
            "Favorly needs your location to show requests near you. Turn on Location for Favorly in Settings."
        case .alreadyReviewed: "You already reviewed this favor."
        case .notEnoughPoints: "You need \(KindnessRules.giftCardCost) points to redeem a gift card."
        case .notSignedIn: "Please sign in again."
        case .rateLimited: "You're doing that too often. Please wait a little and try again."
        case .blocked: "You can't interact with this person."
        case .network: "Can't reach Favorly. Check your connection and try again."
        }
    }
}
