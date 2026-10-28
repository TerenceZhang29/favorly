import FavorlyCore
@testable import FavorlyRemote
import Foundation
import Supabase
import Testing

struct RemoteErrorsTests {
    private func mapped(_ code: String, detail: String? = nil, to status: RequestStatus = .completed) -> FavorlyError? {
        RemoteErrors.favorlyError(
            from: PostgrestError(details: detail, code: "P0001", message: code),
            transitionTo: status
        )
            as? FavorlyError
    }

    @Test(arguments: [
        ("not_signed_in", FavorlyError.notSignedIn),
        ("not_found", .notFound),
        ("already_claimed", .alreadyClaimed),
        ("cannot_claim_own_request", .cannotClaimOwnRequest),
        ("not_allowed", .notAllowed),
        ("already_reviewed", .alreadyReviewed),
        ("rate_limited", .rateLimited),
        ("blocked", .blocked),
    ])
    func everyServerCodeMapsToItsError(code: String, expected: FavorlyError) {
        #expect(mapped(code) == expected)
    }

    @Test func validationCarriesTheServersText() {
        #expect(mapped("validation", detail: "Title must be at least 3 characters.")
            == .validation("Title must be at least 3 characters."))
    }

    @Test func invalidTransitionReadsTheCurrentStatusFromTheDetail() {
        #expect(mapped("invalid_transition", detail: "completed", to: .cancelled)
            == .invalidTransition(from: .completed, to: .cancelled))
    }

    @Test func anUnknownCodeStaysAServerError() {
        #expect(mapped("something_new") == nil)
    }

    @Test func networkAndAuthFailuresMapToo() {
        #expect(RemoteErrors.favorlyError(from: URLError(.notConnectedToInternet)) as? FavorlyError == .network)
        #expect(RemoteErrors.favorlyError(from: AuthError.sessionMissing) as? FavorlyError == .notSignedIn)
    }

    @Test func cancellationAndFavorlyErrorsPassThrough() {
        #expect(RemoteErrors.favorlyError(from: CancellationError()) is CancellationError)
        #expect(RemoteErrors.favorlyError(from: FavorlyError.blocked) as? FavorlyError == .blocked)
    }
}
