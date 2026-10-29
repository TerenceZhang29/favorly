import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Testing

@MainActor
struct PostRequestViewModelTests {
    let world = TestWorld()
    let viewModel: PostRequestViewModel

    init() {
        viewModel = PostRequestViewModel(environment: world.environment)
    }

    @Test func startsEmptyAndCannotSubmit() {
        #expect(viewModel.title.isEmpty)
        #expect(viewModel.category == .other)
        #expect(viewModel.locationState == .loading)
        #expect(viewModel.locationText == nil)
        #expect(viewModel.titleMessage == nil)
        #expect(viewModel.detailsMessage == nil)
        #expect(!viewModel.canSubmit)
    }

    @Test func loadsTheTaggedLocation() async {
        await viewModel.loadLocation()
        #expect(viewModel.locationState == .tagged(LocationPresets.cornellTech.location))
        #expect(viewModel.locationText == "Tagged at Cornell Tech, Roosevelt Island")
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
        viewModel.category = .ingredient

        let created = try #require(await viewModel.submit())

        #expect(created.title == "Need a cup of rice")
        #expect(created.details == "Any kind works.")
        #expect(created.category == .ingredient)
        #expect(created.location == LocationPresets.midtownEast.location)
        #expect(created.requesterID == DemoUsers.alex.id)
        #expect(created.status == .open)
        #expect(try await world.repository.requests(postedBy: DemoUsers.alex.id) == [created])

        #expect(viewModel.title.isEmpty)
        #expect(viewModel.details.isEmpty)
        #expect(viewModel.category == .other)
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
        let viewModel = PostRequestViewModel(environment: world
            .deviceEnvironment(locationProvider: DeniedLocationProvider()))
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

    // MARK: Neighborhood

    @Test func theNeighborhoodStartsAsTheLocationsNameAndCanBeChanged() async throws {
        await viewModel.loadLocation()
        #expect(viewModel.locationLabel == "Cornell Tech, Roosevelt Island")
        viewModel.locationLabel = "Roosevelt Island"
        #expect(viewModel.locationText == "Tagged at Roosevelt Island")

        viewModel.title = "Need a cup of rice"
        let request = try #require(await viewModel.submit())
        #expect(request.location.label == "Roosevelt Island")
        #expect(viewModel.locationLabel == "Roosevelt Island")
    }

    @Test func anInvalidNeighborhoodBlocksPosting() async {
        await viewModel.loadLocation()
        viewModel.title = "Need a cup of rice"
        viewModel.locationLabel = "549 Main St"
        #expect(viewModel.locationLabelMessage == "Use only letters for the neighborhood, not a street address.")
        #expect(viewModel.titleMessage == nil)
        #expect(!viewModel.canSubmit)
        viewModel.locationLabel = ""
        #expect(viewModel.locationLabelMessage == "Add a neighborhood for your request.")
        #expect(viewModel.locationText == "Tagged at your location")
    }

    @Test func aNewLocationReplacesTheNameUnlessTheUserChangedIt() async {
        await viewModel.loadLocation()
        world.locationSettings.selectedPreset = LocationPresets.ithaca
        await viewModel.loadLocation()
        #expect(viewModel.locationLabel == "Ithaca, NY")

        viewModel.locationLabel = "Collegetown"
        world.locationSettings.selectedPreset = LocationPresets.midtownEast
        await viewModel.loadLocation()
        #expect(viewModel.locationLabel == "Collegetown")
    }
}
