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
    }

    @Test func alexStartsWithZeroAndNoActivity() async throws {
        let viewModel = await loadedOwnProfile(as: DemoUsers.alex)
        let content = try #require(viewModel.content)
        #expect(content.user == DemoUsers.alex)
        #expect(content.summary.lifetimePoints == 0)
        #expect(content.activities.isEmpty)
        #expect(content.reviews.isEmpty)
        #expect(viewModel.favorsText == "No favors yet")
        #expect(viewModel.ratingText == "No reviews yet")
    }

    @Test func beaHas90PointsAndHerHistory() async throws {
        let viewModel = await loadedOwnProfile(as: DemoUsers.bea)
        let content = try #require(viewModel.content)
        #expect(content.summary.lifetimePoints == 90)
        #expect(viewModel.favorsText == "5 favors completed")
        #expect(viewModel.ratingText == "5.0 average from 4 reviews")
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
            moderation: repository,
            locationProvider: MockLocationProvider(settings: world.locationSettings),
            session: world.session,
            auth: world.auth,
            push: world.push,
            notifications: world.notifications,
            locationSettings: world.locationSettings
        )
        let viewModel = ProfileViewModel(environment: environment)
        await viewModel.load()
        #expect(viewModel.state == .failed("This request is no longer available."))
    }

    // MARK: Own versus other

    @Test func theProfileTabOffersTheAccount() async {
        let viewModel = await loadedOwnProfile(as: DemoUsers.bea)
        #expect(viewModel.showsAccount)
    }

    @Test func someoneElsesProfileHasNoAccountSection() async throws {
        let viewModel = ProfileViewModel(userID: DemoUsers.bea.id, environment: world.environment)
        await viewModel.load()
        let content = try #require(viewModel.content)
        #expect(!viewModel.showsAccount)
        #expect(content.user == DemoUsers.bea)
        #expect(content.summary.lifetimePoints == 90)
    }

    @Test func yourOwnProfileOpenedFromARequestHasNoAccountSection() {
        world.session.switchUser(to: DemoUsers.bea.id)
        #expect(!ProfileViewModel(userID: DemoUsers.bea.id, environment: world.environment).showsAccount)
    }

    @Test func someoneElsesProfileStaysOnThemAfterAUserSwitch() async {
        let viewModel = ProfileViewModel(userID: DemoUsers.bea.id, environment: world.environment)
        world.session.switchUser(to: DemoUsers.chen.id)
        await viewModel.load()
        #expect(viewModel.content?.user == DemoUsers.bea)
    }

    @Test func anUnknownUserGetsAFallbackName() async {
        let viewModel = ProfileViewModel(userID: UserID(rawValue: "user-nobody"), environment: world.environment)
        await viewModel.load()
        #expect(viewModel.content?.user.displayName == "A neighbor")
        #expect(viewModel.content?.activities == [])
    }

    // MARK: Account

    @Test func signingOutReturnsToWelcome() async {
        let viewModel = await loadedOwnProfile(as: DemoUsers.alex)
        await viewModel.signOut()
        #expect(world.auth.state == .signedOut)
        #expect(viewModel.accountError == nil)
    }

    @Test func deletingTheAccountSignsOutAndForgetsTheUser() async {
        let viewModel = await loadedOwnProfile(as: DemoUsers.bea)
        await viewModel.deleteAccount()
        #expect(world.auth.state == .signedOut)
        #expect(world.session.profile(for: DemoUsers.bea.id) == nil)
        #expect(viewModel.accountError == nil)
        #expect(!viewModel.isDeletingAccount)
    }

    @Test func aFailedDeletionShowsTheMessage() async {
        let viewModel = await loadedOwnProfile(as: DemoUsers.alex)
        // Signed out in another window first, so there is no account to delete here.
        await world.auth.signOut()
        await viewModel.deleteAccount()
        #expect(viewModel.accountError == "You're not allowed to do that.")
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

    @Test func aCompletedFavorRaisesTheScoreWithoutAManualRefresh() async throws {
        let viewModel = await loadedOwnProfile(as: DemoUsers.bea)
        let observing = Task { await viewModel.observeChanges() }
        defer { observing.cancel() }
        await Task.yield()

        try await beaCompletesAFavor()
        #expect(await TestWorld.eventually { viewModel.content?.summary.lifetimePoints == 100 })
        #expect(viewModel.content?.activities.first?.id == TestWorld.eggsID)
    }

    // MARK: Report and block

    @Test func someoneElsesProfileCanBeReportedOrBlocked() {
        #expect(ProfileViewModel(userID: DemoUsers.bea.id, environment: world.environment).canReportOrBlock)
        #expect(!ProfileViewModel(environment: world.environment).canReportOrBlock)
        #expect(!ProfileViewModel(userID: DemoUsers.alex.id, environment: world.environment).canReportOrBlock)
    }

    @Test func blockingFromAProfile() async throws {
        let viewModel = ProfileViewModel(userID: DemoUsers.bea.id, environment: world.environment)
        #expect(await viewModel.block())
        #expect(try await world.repository.blockedUsers(of: DemoUsers.alex.id) == [DemoUsers.bea])
        #expect(await !ProfileViewModel(environment: world.environment).block())
    }

    @Test func signingOutUnregistersTheDevice() async throws {
        try await world.push.register(deviceToken: Data([1, 2, 3]))
        let viewModel = await loadedOwnProfile(as: DemoUsers.alex)
        await viewModel.signOut()
        #expect(await world.push.deviceToken == nil)
    }
}
