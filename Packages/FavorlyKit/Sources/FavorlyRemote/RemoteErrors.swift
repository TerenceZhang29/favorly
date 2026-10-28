import FavorlyCore
import Foundation
import Supabase

/// Turns what the Supabase SDK throws into `FavorlyError`, following the contract in `backend/README.md`.
enum RemoteErrors {
    /// - Parameter transitionTo: The status the action was trying to reach, for `invalidTransition`.
    static func favorlyError(from error: any Error, transitionTo: RequestStatus = .completed) -> any Error {
        switch error {
        case is CancellationError, is FavorlyError:
            error
        case let error as PostgrestError:
            favorlyError(code: error.message, detail: error.details, transitionTo: transitionTo)
        case is URLError:
            FavorlyError.network
        case is AuthError:
            FavorlyError.notSignedIn
        default:
            error
        }
    }

    static func favorlyError(code: String, detail: String?, transitionTo: RequestStatus) -> any Error {
        switch code {
        case "not_signed_in": FavorlyError.notSignedIn
        case "not_found": FavorlyError.notFound
        case "already_claimed": FavorlyError.alreadyClaimed
        case "cannot_claim_own_request": FavorlyError.cannotClaimOwnRequest
        case "not_allowed": FavorlyError.notAllowed
        case "invalid_transition":
            FavorlyError.invalidTransition(
                from: detail.flatMap(RequestStatus.init(rawValue:)) ?? .open,
                to: transitionTo
            )
        case "validation": FavorlyError.validation(detail ?? "")
        case "already_reviewed": FavorlyError.alreadyReviewed
        case "rate_limited": FavorlyError.rateLimited
        case "blocked": FavorlyError.blocked
        default: PostgrestError(details: detail, message: code)
        }
    }
}
