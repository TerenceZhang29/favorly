import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Testing

@MainActor
struct DisplayTests {
    @Test func radiusOptionsMatchThePlan() {
        #expect(RadiusOption.allCases.map(\.miles) == [0.25, 0.5, 1, 3])
        #expect(RadiusOption.allCases.map(\.title) == ["0.25 mi", "0.5 mi", "1 mi", "3 mi"])
        #expect(RadiusOption.default == .oneMile)
        #expect(RadiusOption.oneMile.meters == 1609.344)
    }

    @Test func everyCategoryHasADistinctTitleAndIcon() {
        let categories = RequestCategory.allCases
        #expect(categories.map(\.title) == ["Ingredient", "Moving help", "Car help", "Errand", "Other"])
        #expect(Set(categories.map(\.systemImage)).count == categories.count)
    }

    @Test func statusTitlesAreReadable() {
        let statuses: [RequestStatus] = [.open, .claimed, .completed, .cancelled]
        #expect(statuses.map(\.title) == ["Open", "Claimed", "Completed", "Cancelled"])
    }

    @Test func displayNameFallsBackForAnUnknownUser() {
        let session = MockSessionStore()
        #expect(session.displayName(for: DemoUsers.bea.id) == "Bea")
        #expect(session.displayName(for: UserID(rawValue: "user-nobody")) == "A neighbor")
    }

    @Test(arguments: [
        (FavorlyError.notFound, "This request is no longer available."),
        (.alreadyClaimed, "Someone else already picked this up."),
        (.cannotClaimOwnRequest, "You can't pick up your own request."),
        (.notAllowed, "You're not allowed to do that."),
        (.invalidTransition(from: .completed, to: .cancelled), "This request can't be changed that way anymore."),
        (.validation("Title must be at least 3 characters."), "Title must be at least 3 characters."),
        (.locationUnavailable, "Your location isn't available right now."),
        (.alreadyReviewed, "You already reviewed this favor."),
        (.notEnoughPoints, "You need 100 points to redeem a gift card."),
        (.notSignedIn, "Please sign in again."),
        (.rateLimited, "You're doing that too often. Please wait a little and try again."),
        (.blocked, "You can't interact with this person."),
        (.network, "Can't reach Favorly. Check your connection and try again."),
    ])
    func everyFavorlyErrorHasAUserMessage(error: FavorlyError, expected: String) {
        #expect(ErrorMessage.text(for: error) == expected)
    }

    @Test func otherErrorsGetAGenericMessage() {
        #expect(ErrorMessage.text(for: CancellationError()) == "Something went wrong. Please try again.")
    }
}
