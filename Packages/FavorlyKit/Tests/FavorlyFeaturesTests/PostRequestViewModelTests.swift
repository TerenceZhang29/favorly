import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Foundation
import Testing

@MainActor
struct PostRequestViewModelTests {
    let world = TestWorld()
    /// A fresh store per test, so the last picked neighborhood never leaks between tests.
    let defaults = UserDefaults(suiteName: "PostRequestViewModelTests-\(UUID().uuidString)")!
    let viewModel: PostRequestViewModel

    init() {
        viewModel = PostRequestViewModel(environment: world.environment, defaults: defaults)
    }

    @Test func startsEmptyAndCannotSubmit() {
        #expect(viewModel.title.isEmpty)
        #expect(viewModel.locationState == .loading)
        #expect(viewModel.locationText == nil)
        #expect(viewModel.titleMessage == nil)
        #expect(viewModel.detailsMessage == nil)
        #expect(!viewModel.canSubmit)
    }

    @Test func loadsTheTaggedLocation() async {
        await viewModel.loadLocation()
        #expect(viewModel.locationState == .tagged(LocationPresets.cornellTech.location))
        #expect(viewModel
            .neighborhoodState == .loaded(DemoNeighborhoods.names(near: LocationPresets.cornellTech.location.point)))
        #expect(viewModel.locationText == "Tagged at Roosevelt Island")
    }

    @Test func titleIsValidatedAsTheUserTypes() async {
        await viewModel.loadLocation()

        viewModel.title = "ab"
        #expect(viewModel.titleMessage == "Title must be at least 3 characters.")
        #expect(!viewModel.canSubmit)

        viewModel.title = "   "
        #expect(viewModel.titleMessage == "Title must be at least 3 characters.")

        viewModel.title = String(repeating: "a", count: 81)
        #expect(viewModel.titleMessage == "Title must be 80 characters or fewer.")

        viewModel.title = "Need a cup of rice"
        #expect(viewModel.titleMessage == nil)
        #expect(viewModel.canSubmit)
    }

    @Test func detailsOverTheLimitBlockSubmit() async {
        await viewModel.loadLocation()
        viewModel.title = "Need a cup of rice"
        viewModel.details = String(repeating: "d", count: 501)
        #expect(viewModel.detailsMessage == "Details must be 500 characters or fewer.")
        #expect(viewModel.titleMessage == nil)
        #expect(!viewModel.canSubmit)
    }

    @Test func invalidTitleBlocksSubmit() async throws {
        await viewModel.loadLocation()
        viewModel.title = "ab"

        #expect(await viewModel.submit() == nil)
        #expect(try await world.repository.requests(postedBy: DemoUsers.alex.id).isEmpty)
        #expect(viewModel.title == "ab")
    }

    @Test func submitIsBlockedUntilTheLocationIsKnown() async throws {
        viewModel.title = "Need a cup of rice"
        #expect(!viewModel.canSubmit)
        #expect(await viewModel.submit() == nil)
        #expect(try await world.repository.requests(postedBy: DemoUsers.alex.id).isEmpty)
    }

    @Test func successfulSubmitCreatesARequestAtTheCurrentPresetAndResetsTheForm() async throws {
        world.locationSettings.selectedPreset = LocationPresets.midtownEast
        await viewModel.loadLocation()
        viewModel.title = "  Need a cup of rice "
        viewModel.details = "Any kind works."

        let created = try #require(await viewModel.submit())

        #expect(created.title == "Need a cup of rice")
        #expect(created.details == "Any kind works.")
        #expect(created.location == TaggedLocation(
            point: LocationPresets.midtownEast.location.point,
            label: "East Midtown"
        ))
        #expect(created.requesterID == DemoUsers.alex.id)
        #expect(created.status == .open)
        #expect(try await world.repository.requests(postedBy: DemoUsers.alex.id) == [created])

        #expect(viewModel.title.isEmpty)
        #expect(viewModel.details.isEmpty)
        #expect(viewModel.submitError == nil)
        #expect(!viewModel.isSubmitting)
        #expect(!viewModel.canSubmit)
    }

    @Test func submitPostsAsWhoeverIsSignedInAtThatMoment() async throws {
        await viewModel.loadLocation()
        viewModel.title = "Need a cup of rice"
        world.session.switchUser(to: DemoUsers.dana.id)

        let created = try #require(await viewModel.submit())
        #expect(created.requesterID == DemoUsers.dana.id)
    }

    @Test func locationErrorBlocksSubmitUntilItRecovers() async {
        world.locationSettings.simulatesError = true
        await viewModel.loadLocation()
        viewModel.title = "Need a cup of rice"
        #expect(viewModel.locationState == .failed("Your location isn't available right now."))
        #expect(viewModel.locationText == nil)
        #expect(!viewModel.canSubmit)

        world.locationSettings.simulatesError = false
        await viewModel.loadLocation()
        #expect(viewModel.canSubmit)
    }

    @Test func reloadKeyChangesWithLocationAndErrorToggle() {
        let initial = viewModel.reloadKey
        world.locationSettings.selectedPreset = LocationPresets.ithaca
        let afterMove = viewModel.reloadKey
        world.locationSettings.simulatesError = true
        #expect(Set([initial, afterMove, viewModel.reloadKey]).count == 3)
    }

    // MARK: Device location

    @Test func aDeniedLocationOffersSettingsAndBlocksSubmit() async {
        let viewModel = PostRequestViewModel(
            environment: world.deviceEnvironment(locationProvider: DeniedLocationProvider()),
            defaults: defaults
        )
        viewModel.title = "Need a cup of rice"
        await viewModel.loadLocation()
        #expect(viewModel.locationState == .denied(
            "Favorly needs your location to show requests near you. Turn on Location for Favorly in Settings."
        ))
        #expect(viewModel.locationText == nil)
        #expect(!viewModel.canSubmit)
        #expect(viewModel.reloadKey.preset == nil)
    }

    // MARK: Notifications

    @Test func aSuccessfulPostAsksForNotificationsAndAFailedOneDoesNot() async {
        await viewModel.loadLocation()
        viewModel.title = "Hi"
        _ = await viewModel.submit()
        #expect(world.notifications.permissionRequests == 0)

        viewModel.title = "Need a cup of rice"
        _ = await viewModel.submit()
        #expect(world.notifications.permissionRequests == 1)
    }

    // MARK: Neighborhood and meeting spot

    @Test func theNeighborhoodIsPickedFromTheOfferedNames() async throws {
        await viewModel.loadLocation()
        #expect(viewModel.neighborhood == "Roosevelt Island")
        viewModel.neighborhood = "Long Island City"
        #expect(viewModel.locationText == "Tagged at Long Island City")

        viewModel.title = "Need a cup of rice"
        let request = try #require(await viewModel.submit())
        #expect(request.location.label == "Long Island City")
    }

    @Test func aNameThatIsNotOfferedBlocksPosting() async {
        await viewModel.loadLocation()
        viewModel.title = "Need a cup of rice"
        viewModel.neighborhood = "Seattle"
        #expect(!viewModel.canSubmit)
    }

    @Test func theLastPostsNeighborhoodIsOfferedFirstNextTime() async throws {
        await viewModel.loadLocation()
        viewModel.neighborhood = "Turtle Bay"
        viewModel.title = "Need a cup of rice"
        _ = try #require(await viewModel.submit())
        #expect(defaults.string(forKey: PostRequestViewModel.lastNeighborhoodKey) == "Turtle Bay")

        let next = PostRequestViewModel(environment: world.environment, defaults: defaults)
        await next.loadLocation()
        #expect(next.neighborhood == "Turtle Bay")

        // Somewhere it is not offered, the first name is.
        world.locationSettings.selectedPreset = LocationPresets.longIslandCity
        await next.loadLocation()
        #expect(next.neighborhood == "Long Island City")
    }

    @Test func aNewLocationKeepsThePickIfStillOffered() async {
        await viewModel.loadLocation()
        viewModel.neighborhood = "Queensbridge"
        world.locationSettings.selectedPreset = LocationPresets.rooseveltIslandNorth
        await viewModel.loadLocation()
        #expect(viewModel.neighborhood == "Queensbridge")

        world.locationSettings.selectedPreset = LocationPresets.midtownEast
        await viewModel.loadLocation()
        #expect(viewModel.neighborhood == "East Midtown")
    }

    @Test func withoutDataTheLocationsOwnNameIsTheOnlyChoice() async {
        world.locationSettings.selectedPreset = LocationPresets.ithaca
        await viewModel.loadLocation()
        #expect(viewModel.neighborhoodChoices == ["Ithaca, NY"])
        #expect(viewModel.neighborhood == "Ithaca, NY")
    }

    @Test func aFailedLookupBlocksPostingUntilTryAgainWorks() async {
        let neighborhoods = FlakyNeighborhoods()
        let viewModel = PostRequestViewModel(environment: environment(neighborhoods: neighborhoods), defaults: defaults)
        viewModel.title = "Need a cup of rice"
        await viewModel.loadLocation()
        #expect(viewModel.neighborhoodState == .failed("Can't reach Favorly. Check your connection and try again."))
        #expect(viewModel.locationText == nil)
        #expect(!viewModel.canSubmit)

        await neighborhoods.recover()
        await viewModel.loadNeighborhoods()
        #expect(viewModel.neighborhoodChoices == ["Roosevelt Island"])
        #expect(viewModel.canSubmit)
    }

    @Test func theMeetingSpotIsOptionalCheckedAndCleared() async throws {
        await viewModel.loadLocation()
        viewModel.title = "Need a cup of rice"
        #expect(viewModel.meetingSpotMessage == nil)

        viewModel.meetingSpot = "Apt 4B"
        #expect(viewModel.meetingSpotMessage == "Use only letters for the meeting spot, not a street address.")
        #expect(!viewModel.canSubmit)

        viewModel.meetingSpot = "  Cornell Tech lobby "
        let request = try #require(await viewModel.submit())
        #expect(request.meetingSpot == "Cornell Tech lobby")
        #expect(viewModel.meetingSpot.isEmpty)
    }

    private func environment(neighborhoods: any NeighborhoodDirectory) -> AppEnvironment {
        let base = world.environment
        return AppEnvironment(
            repository: base.repository,
            kindness: base.kindness,
            reviews: base.reviews,
            chat: base.chat,
            moderation: base.moderation,
            neighborhoods: neighborhoods,
            locationProvider: base.locationProvider,
            session: base.session,
            auth: base.auth,
            push: base.push,
            notifications: base.notifications,
            locationSettings: base.locationSettings
        )
    }
}
