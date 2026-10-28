import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Foundation
import Testing

@MainActor
struct RequestDetailViewModelTests {
    let world = TestWorld()

    private func makeViewModel(_ id: RequestID = TestWorld.eggsID) -> RequestDetailViewModel {
        RequestDetailViewModel(requestID: id, environment: world.environment)
    }

    private func loaded(_ id: RequestID = TestWorld.eggsID, as user: UserProfile) async -> RequestDetailViewModel {
        world.session.switchUser(to: user.id)
        let viewModel = makeViewModel(id)
        await viewModel.load()
        return viewModel
    }

    // MARK: Loading

    @Test func loadShowsTheRequestWithNamesAndDistance() async {
        let viewModel = makeViewModel()
        #expect(viewModel.state == .loading)
        #expect(!viewModel.canPickUp)

        await viewModel.load()

        #expect(viewModel.request?.title == "Need 2 eggs for a cake")
        #expect(viewModel.requesterName == "Chen")
        #expect(viewModel.helperName == nil)
        #expect(viewModel.statusText == "Open")
        #expect(viewModel.distanceText == "< 0.1 mi")
        #expect(!viewModel.isOwn)
    }

    @Test func distanceIsLeftOutWhenTheLocationIsUnavailable() async {
        world.locationSettings.simulatesError = true
        let viewModel = makeViewModel()
        await viewModel.load()
        #expect(viewModel.request != nil)
        #expect(viewModel.distanceText == nil)
    }

    @Test func missingRequestShowsAnError() async {
        let viewModel = makeViewModel(RequestID(rawValue: UUID()))
        await viewModel.load()
        #expect(viewModel.state == .failed("This request is no longer available."))
    }

    // MARK: Available actions

    @Test func anotherUserCanOnlyPickUpAnOpenRequest() async {
        let viewModel = await loaded(as: DemoUsers.bea)
        #expect(viewModel.canPickUp)
        #expect(!viewModel.canCancel)
        #expect(!viewModel.canComplete)
    }

    @Test func ownOpenRequestShowsNoPickUpOnlyCancel() async {
        let viewModel = await loaded(as: DemoUsers.chen)
        #expect(viewModel.isOwn)
        #expect(!viewModel.canPickUp)
        #expect(viewModel.canCancel)
        #expect(!viewModel.canComplete)
    }

    @Test func claimedRequestActionsDependOnTheUser() async {
        let requester = await loaded(TestWorld.ladderID, as: DemoUsers.dana)
        #expect(requester.statusText == "Claimed by Chen")
        #expect(requester.helperName == "Chen")
        #expect([requester.canPickUp, requester.canCancel, requester.canComplete] == [false, true, true])

        let helper = await loaded(TestWorld.ladderID, as: DemoUsers.chen)
        #expect([helper.canPickUp, helper.canCancel, helper.canComplete] == [false, false, false])

        let stranger = await loaded(TestWorld.ladderID, as: DemoUsers.alex)
        #expect([stranger.canPickUp, stranger.canCancel, stranger.canComplete] == [false, false, false])
    }

    @Test func actionsFollowAUserSwitchWithoutReloading() async {
        let viewModel = await loaded(as: DemoUsers.bea)
        world.session.switchUser(to: DemoUsers.chen.id)
        #expect(!viewModel.canPickUp)
        #expect(viewModel.canCancel)
    }

    // MARK: Actions

    @Test func pickUpChangesTheStatusAndShowsTheHelperName() async throws {
        let viewModel = await loaded(as: DemoUsers.bea)
        await viewModel.pickUp()

        #expect(viewModel.request?.status == .claimed)
        #expect(viewModel.helperName == "Bea")
        #expect(viewModel.statusText == "Claimed by Bea")
        #expect(viewModel.actionError == nil)
        #expect(!viewModel.isWorking)
        #expect([viewModel.canPickUp, viewModel.canCancel, viewModel.canComplete] == [false, false, false])
        #expect(viewModel.autoCompleteNote != nil)
        #expect(try await world.repository.request(id: TestWorld.eggsID).helperID == DemoUsers.bea.id)
    }

    @Test func pickUpAfterSomeoneElseShowsAnErrorAndTheirClaim() async throws {
        let viewModel = await loaded(as: DemoUsers.bea)
        _ = try await world.repository.claim(TestWorld.eggsID, by: DemoUsers.dana.id)

        await viewModel.pickUp()

        #expect(viewModel.actionError == "Someone else already picked this up.")
        #expect(viewModel.statusText == "Claimed by Dana")
        #expect(!viewModel.canPickUp)
    }

    @Test func aSuccessfulActionClearsAnEarlierError() async throws {
        let viewModel = await loaded(as: DemoUsers.bea)
        _ = try await world.repository.claim(TestWorld.eggsID, by: DemoUsers.dana.id)
        await viewModel.pickUp()
        #expect(viewModel.actionError != nil)

        world.session.switchUser(to: DemoUsers.chen.id)
        await viewModel.complete()
        #expect(viewModel.actionError == nil)
        #expect(viewModel.statusText == "Completed")
    }

    @Test func requesterCanCancel() async {
        let viewModel = await loaded(as: DemoUsers.chen)
        await viewModel.cancel()
        #expect(viewModel.statusText == "Cancelled")
        #expect([viewModel.canPickUp, viewModel.canCancel, viewModel.canComplete] == [false, false, false])
    }

    @Test func requesterCanMarkCompleted() async {
        let viewModel = await loaded(TestWorld.ladderID, as: DemoUsers.dana)
        #expect(viewModel.canComplete)
        await viewModel.complete()
        #expect(viewModel.statusText == "Completed")
        #expect(viewModel.helperName == "Chen")
    }

    // MARK: Auto-complete

    @Test func theHelperCannotCompleteAndSeesWhenItCompletesOnItsOwn() async throws {
        let viewModel = await loaded(TestWorld.ladderID, as: DemoUsers.chen)
        #expect(!viewModel.canComplete)

        let claimedAt = try #require(viewModel.request?.claimedAt)
        let date = claimedAt.addingTimeInterval(RequestRules.autoCompleteInterval)
        #expect(viewModel.autoCompleteDate == date)
        let day = date.formatted(.dateTime.month(.abbreviated).day())
        #expect(viewModel.autoCompleteNote == "Completes automatically on \(day) if Dana doesn't confirm.")
    }

    @Test func onlyTheHelperOfAPickedUpRequestSeesTheNote() async {
        #expect(await loaded(TestWorld.ladderID, as: DemoUsers.dana).autoCompleteNote == nil)
        #expect(await loaded(TestWorld.ladderID, as: DemoUsers.alex).autoCompleteNote == nil)
        #expect(await loaded(TestWorld.seedID(12), as: DemoUsers.bea).autoCompleteNote == nil)
        #expect(await loaded(as: DemoUsers.bea).autoCompleteNote == nil)
    }

    @Test func theHelperGetsAnErrorIfTheyTryToComplete() async {
        let viewModel = await loaded(TestWorld.ladderID, as: DemoUsers.chen)
        await viewModel.complete()
        #expect(viewModel.actionError == "You're not allowed to do that.")
        #expect(viewModel.statusText == "Claimed by Chen")
    }

    @Test func anActionThatIsNotAllowedShowsAnError() async {
        let viewModel = await loaded(as: DemoUsers.bea)
        await viewModel.cancel()
        #expect(viewModel.actionError == "You're not allowed to do that.")
        #expect(viewModel.statusText == "Open")
    }

    // MARK: Changes

    @Test func aChangeMadeElsewhereIsReflected() async throws {
        let viewModel = await loaded(as: DemoUsers.alex)
        let observing = Task { await viewModel.observeChanges() }
        defer { observing.cancel() }
        await Task.yield()

        _ = try await world.repository.claim(TestWorld.eggsID, by: DemoUsers.bea.id)

        #expect(await TestWorld.eventually { viewModel.statusText == "Claimed by Bea" })
    }

    // MARK: Kindness scores

    @Test func scoresShowBesideTheRequesterAndHelper() async {
        let saffron = await loaded(TestWorld.seedID(12), as: DemoUsers.alex)
        #expect(saffron.requesterScore == 0)
        #expect(saffron.helperScore == 90)

        let eggs = await loaded(as: DemoUsers.alex)
        #expect(eggs.requesterScore == 18)
        #expect(eggs.helperScore == nil)
    }

    @Test func pickingUpShowsTheHelpersScore() async {
        let viewModel = await loaded(as: DemoUsers.bea)
        await viewModel.pickUp()
        #expect(viewModel.helperScore == 90)
    }

    @Test func completingRaisesTheHelpersScore() async {
        let viewModel = await loaded(TestWorld.ladderID, as: DemoUsers.dana)
        #expect(viewModel.helperScore == 18)
        await viewModel.complete()
        #expect(viewModel.helperScore == 28)
    }

    // MARK: Chat entry point

    @Test func noMessageButtonBeforePickUp() async {
        let viewModel = await loaded(as: DemoUsers.chen)
        #expect(!viewModel.canMessage)
    }

    @Test func requesterAndHelperCanMessageEachOther() async {
        let asRequester = await loaded(TestWorld.ladderID, as: DemoUsers.dana)
        #expect(asRequester.canMessage)
        #expect(asRequester.messageButtonTitle == "Message Chen")

        let asHelper = await loaded(TestWorld.ladderID, as: DemoUsers.chen)
        #expect(asHelper.canMessage)
        #expect(asHelper.messageButtonTitle == "Message Dana")
    }

    @Test func othersCannotMessage() async {
        let viewModel = await loaded(TestWorld.ladderID, as: DemoUsers.alex)
        #expect(!viewModel.canMessage)
    }

    @Test func aCompletedRequestStillOpensItsThread() async {
        let viewModel = await loaded(TestWorld.seedID(12), as: DemoUsers.dana)
        #expect(viewModel.canMessage)
        #expect(viewModel.messageButtonTitle == "Message Bea")
    }

    // MARK: Reviews

    @Test func theRequesterCanReviewACompletedRequestOnce() async throws {
        let viewModel = await loaded(TestWorld.seedID(12), as: DemoUsers.dana)
        #expect(viewModel.canReview)
        #expect(viewModel.review == nil)

        _ = try await world.repository.submitReview(
            NewReviewDraft(rating: 5, comment: "Fast and friendly"),
            for: TestWorld.seedID(12),
            by: DemoUsers.dana.id
        )
        await viewModel.load()

        #expect(!viewModel.canReview)
        #expect(viewModel.review?.comment == "Fast and friendly")
        #expect(viewModel.reviewTitle == "Your review")
        #expect(viewModel.helperScore == 100)
    }

    @Test func othersSeeTheReviewButCannotReview() async {
        let asHelper = await loaded(TestWorld.seedID(17), as: DemoUsers.chen)
        #expect(!asHelper.canReview)
        #expect(asHelper.review?.rating == 4)
        #expect(asHelper.reviewTitle == "Review")

        let asHelperOfSaffron = await loaded(TestWorld.seedID(12), as: DemoUsers.bea)
        #expect(!asHelperOfSaffron.canReview)
    }

    @Test func anOpenOrClaimedRequestCannotBeReviewed() async {
        #expect(await !loaded(as: DemoUsers.chen).canReview)
        #expect(await !loaded(TestWorld.ladderID, as: DemoUsers.dana).canReview)
    }

    @Test func completingARequestOffersTheReview() async {
        let viewModel = await loaded(TestWorld.ladderID, as: DemoUsers.dana)
        await viewModel.complete()
        #expect(viewModel.canReview)
    }
}
