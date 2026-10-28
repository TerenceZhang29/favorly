import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Foundation
import Testing

@MainActor
struct ProfileViewModelTests {
    let world = TestWorld()

    private func loadedOwnProfile(as user: UserProfile) async -> ProfileViewModel {
        world.session.switchUser(to: user.id)
        let viewModel = ProfileViewModel(environment: world.environment)
        await viewModel.load()
        return viewModel
    }

    /// Bea picks up Chen's eggs request and completes it, taking her to 100 points.
    private func beaCompletesAFavor() async throws {
        _ = try await world.repository.claim(TestWorld.eggsID, by: DemoUsers.bea.id)
        _ = try await world.repository.complete(TestWorld.eggsID, by: DemoUsers.chen.id)
    }

    // MARK: States

    @Test func startsLoading() {
        let viewModel = ProfileViewModel(environment: world.environment)
        #expect(viewModel.state == .loading)
        #expect(viewModel.content == nil)
        #expect(!viewModel.canRedeem)
    }

    @Test func alexStartsWithZeroAndNoActivity() async throws {
        let viewModel = await loadedOwnProfile(as: DemoUsers.alex)
        let content = try #require(viewModel.content)
        #expect(content.user == DemoUsers.alex)
        #expect(content.summary.lifetimePoints == 0)
        #expect(content.activities.isEmpty)
        #expect(content.reviews.isEmpty)
        #expect(content.redemptions == [])
        #expect(viewModel.favorsText == "No favors yet")
        #expect(viewModel.ratingText == "No reviews yet")
        #expect(viewModel.giftCardProgressText == "0 of 100 points")
        #expect(viewModel.giftCardProgress == 0)
        #expect(!viewModel.canRedeem)
    }

    @Test func beaHas90PointsAndHerHistory() async throws {
        let viewModel = await loadedOwnProfile(as: DemoUsers.bea)
        let content = try #require(viewModel.content)
        #expect(content.summary.lifetimePoints == 90)
        #expect(viewModel.favorsText == "5 favors completed")
        #expect(viewModel.ratingText == "5.0 average from 4 reviews")
        #expect(viewModel.giftCardProgressText == "90 of 100 points")
        #expect(viewModel.giftCardProgress == 0.9)
        #expect(!viewModel.canRedeem)
        #expect(content.reviews.count == 4)

        // Saffron (12) and 13–16 as helper, 17 as requester, newest pick-up first.
        #expect(content.activities.map(\.id) == [12, 17, 13, 14, 15, 16].map { TestWorld.seedID($0) })
        #expect(content.activities.first?.role == .helped)
        #expect(content.activities.first { $0.id == TestWorld.seedID(17) }?.role == .asked)
    }

    @Test func activitiesListCompletedRequestsOnly() async throws {
        let viewModel = await loadedOwnProfile(as: DemoUsers.chen)
        let content = try #require(viewModel.content)
        #expect(content.activities.allSatisfy { $0.request.status == .completed })
        // Chen asked for 13 and 15, helped with 17; the claimed ladder request and his open ones are left out.
        #expect(Set(content.activities.map(\.id)) == Set([13, 15, 17].map { TestWorld.seedID($0) }))
        #expect(viewModel.favorsText == "1 favor completed")
        #expect(viewModel.ratingText == "4.0 average from 1 review")
    }

    @Test func aLoadErrorOffersTheMessage() async {
        let repository = MockRequestRepository(artificialDelay: .zero)
        let environment = AppEnvironment(
            repository: repository,
            kindness: FailingKindnessRepository(),
            reviews: repository,
            chat: repository,
            locationProvider: MockLocationProvider(settings: world.locationSettings),
            session: world.session,
            locationSettings: world.locationSettings
        )
        let viewModel = ProfileViewModel(environment: environment)
        await viewModel.load()
        #expect(viewModel.state == .failed("This request is no longer available."))
    }

    // MARK: Own versus other

    @Test func ownProfileShowsTheGiftCard() async {
        let viewModel = await loadedOwnProfile(as: DemoUsers.bea)
        #expect(viewModel.isOwn)
        #expect(viewModel.content?.redemptions == [])
    }

    @Test func someoneElsesProfileHasNoGiftCard() async throws {
        let viewModel = ProfileViewModel(userID: DemoUsers.bea.id, environment: world.environment)
        await viewModel.load()
        let content = try #require(viewModel.content)
        #expect(!viewModel.isOwn)
        #expect(content.user == DemoUsers.bea)
        #expect(content.summary.lifetimePoints == 90)
        #expect(content.redemptions == nil)
        #expect(!viewModel.canRedeem)
    }

    @Test func someoneElsesProfileStaysOnThemAfterAUserSwitch() async {
        let viewModel = ProfileViewModel(userID: DemoUsers.bea.id, environment: world.environment)
        world.session.switchUser(to: DemoUsers.chen.id)
        await viewModel.load()
        #expect(viewModel.content?.user == DemoUsers.bea)
        world.session.switchUser(to: DemoUsers.bea.id)
        #expect(viewModel.isOwn)
    }

    @Test func anUnknownUserGetsAFallbackName() async {
        let viewModel = ProfileViewModel(userID: UserID(rawValue: "user-nobody"), environment: world.environment)
        await viewModel.load()
        #expect(viewModel.content?.user.displayName == "A neighbor")
        #expect(viewModel.content?.activities == [])
    }

    // MARK: Redeem

    @Test func redeemAt100ShowsTheCodeAndResetsProgress() async throws {
        try await beaCompletesAFavor()
        let viewModel = await loadedOwnProfile(as: DemoUsers.bea)
        #expect(viewModel.giftCardProgressText == "100 of 100 points")
        #expect(viewModel.giftCardProgress == 1)
        #expect(viewModel.canRedeem)

        await viewModel.redeem()

        #expect(viewModel.latestRedemption?.code == "FAVORLY-0001")
        #expect(viewModel.redeemError == nil)
        #expect(viewModel.content?.summary.lifetimePoints == 100)
        #expect(viewModel.giftCardProgressText == "0 of 100 points")
        #expect(viewModel.content?.redemptions?.map(\.code) == ["FAVORLY-0001"])
        #expect(!viewModel.canRedeem)
    }

    @Test func redeemBelow100DoesNothing() async throws {
        let viewModel = await loadedOwnProfile(as: DemoUsers.bea)
        await viewModel.redeem()
        #expect(viewModel.latestRedemption == nil)
        #expect(try await world.repository.redemptions(by: DemoUsers.bea.id).isEmpty)
    }

    @Test func aFailedRedeemShowsTheMessage() async throws {
        try await beaCompletesAFavor()
        let viewModel = await loadedOwnProfile(as: DemoUsers.bea)
        // Someone else spends the points first, in another window of the same account.
        _ = try await world.repository.redeemGiftCard(by: DemoUsers.bea.id)
        await viewModel.redeem()
        #expect(viewModel.redeemError == "You need 100 points to redeem a gift card.")
        #expect(viewModel.latestRedemption == nil)
    }

    // MARK: Reloading

    @Test func reloadKeyFollowsTheCurrentUserAndASwitchReloads() async {
        let viewModel = await loadedOwnProfile(as: DemoUsers.alex)
        #expect(viewModel.reloadKey == DemoUsers.alex.id)
        world.session.switchUser(to: DemoUsers.bea.id)
        #expect(viewModel.reloadKey == DemoUsers.bea.id)
        await viewModel.load()
        #expect(viewModel.content?.user == DemoUsers.bea)
        #expect(viewModel.content?.summary.lifetimePoints == 90)
    }

    @Test func aSwitchClearsTheRedeemedCode() async throws {
        try await beaCompletesAFavor()
        let viewModel = await loadedOwnProfile(as: DemoUsers.bea)
        await viewModel.redeem()
        world.session.switchUser(to: DemoUsers.alex.id)
        await viewModel.load()
        #expect(viewModel.latestRedemption == nil)
    }

    @Test func aCompletedFavorRaisesTheScoreWithoutAManualRefresh() async throws {
        let viewModel = await loadedOwnProfile(as: DemoUsers.bea)
        let observing = Task { await viewModel.observeChanges() }
        defer { observing.cancel() }
        await Task.yield()

        try await beaCompletesAFavor()
        #expect(await TestWorld.eventually { viewModel.content?.summary.lifetimePoints == 100 })
        #expect(viewModel.content?.activities.first?.id == TestWorld.eggsID)
    }
}
