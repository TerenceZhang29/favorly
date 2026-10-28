import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Testing

@MainActor
struct NearbyViewModelTests {
    let world = TestWorld()
    let viewModel: NearbyViewModel

    init() {
        viewModel = NearbyViewModel(environment: world.environment)
    }

    private var results: [NearbyRequest] {
        guard case let .loaded(results) = viewModel.state else { return [] }
        return results
    }

    @Test func startsLoadingWithTheDefaultRadius() {
        #expect(viewModel.state == .loading)
        #expect(viewModel.radius == .oneMile)
        #expect(viewModel.countText == nil)
    }

    @Test func loadShowsOpenRequestsWithinTheRadiusClosestFirst() async {
        await viewModel.load()
        #expect(results.count == 7)
        #expect(results.first?.id == TestWorld.eggsID)
        #expect(results.map(\.distanceMeters) == results.map(\.distanceMeters).sorted())
        #expect(viewModel.countText == "7 requests")
    }

    @Test(arguments: [
        (RadiusOption.quarterMile, 3),
        (.halfMile, 5),
        (.oneMile, 7),
        (.threeMiles, 8),
    ])
    func radiusChangeRefilters(radius: RadiusOption, expectedCount: Int) async {
        await viewModel.load()
        viewModel.radius = radius
        await viewModel.load()
        #expect(results.count == expectedCount)
    }

    @Test func farAwayLocationShowsTheEmptyState() async {
        world.locationSettings.selectedPreset = LocationPresets.ithaca
        await viewModel.load()
        #expect(viewModel.state == .empty)
        #expect(viewModel.emptyMessage == "No requests within 1 mi")
        #expect(viewModel.countText == nil)
    }

    @Test func locationErrorShowsAMessageAndRetryRecovers() async {
        world.locationSettings.simulatesError = true
        await viewModel.load()
        #expect(viewModel.state == .failed("Your location isn't available right now."))

        world.locationSettings.simulatesError = false
        await viewModel.load()
        #expect(results.count == 7)
    }

    @Test func ownRequestsAreFlaggedForTheCurrentUser() async throws {
        await viewModel.load()
        let eggs = try #require(results.first { $0.id == TestWorld.eggsID }).request
        #expect(!viewModel.isOwn(eggs))
        #expect(viewModel.requesterName(for: eggs) == "Chen")

        world.session.switchUser(to: DemoUsers.chen.id)
        #expect(viewModel.isOwn(eggs))
    }

    @Test func reloadKeyChangesWithLocationErrorToggleAndRadius() {
        let initial = viewModel.reloadKey
        world.locationSettings.selectedPreset = LocationPresets.midtownEast
        let afterMove = viewModel.reloadKey
        world.locationSettings.simulatesError = true
        let afterError = viewModel.reloadKey
        viewModel.radius = .threeMiles
        #expect(Set([initial, afterMove, afterError, viewModel.reloadKey]).count == 4)
    }

    @Test func aClaimMadeElsewhereRemovesTheRequestFromTheList() async throws {
        await viewModel.load()
        let observing = Task { await viewModel.observeChanges() }
        defer { observing.cancel() }
        await Task.yield()

        _ = try await world.repository.claim(TestWorld.eggsID, by: DemoUsers.bea.id)

        #expect(await TestWorld.eventually { results.count == 6 })
        #expect(!results.contains { $0.id == TestWorld.eggsID })
    }

    @Test func countTextUsesTheSingularForOneRequest() async {
        world.locationSettings.selectedPreset = LocationPresets.rooseveltIslandNorth
        viewModel.radius = .quarterMile
        await viewModel.load()
        #expect(viewModel.countText == "1 request")
    }

    // MARK: Device location

    @Test func theHeaderNamesTheNeighborhoodOnceLoaded() async {
        #expect(viewModel.locationText == nil)
        await viewModel.load()
        #expect(viewModel.locationText == "Near Cornell Tech, Roosevelt Island")
    }

    @Test func aDeniedLocationOffersSettingsInsteadOfRetry() async {
        let viewModel = NearbyViewModel(environment: world
            .deviceEnvironment(locationProvider: DeniedLocationProvider()))
        await viewModel.load()
        #expect(viewModel.state == .locationDenied(
            "Favorly needs your location to show requests near you. Turn on Location for Favorly in Settings."
        ))
        #expect(viewModel.locationText == "Location is off")
        #expect(viewModel.countText == nil)
    }

    @Test func theDevicesLocationHasNoPresetInTheReloadKey() {
        let viewModel = NearbyViewModel(environment: world
            .deviceEnvironment(locationProvider: DeniedLocationProvider()))
        #expect(viewModel.reloadKey.preset == nil)
        #expect(!viewModel.reloadKey.simulatesError)
    }
}
