import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Testing

/// The Kindness score pill in the Nearby header, as in the Grove mockup.
@MainActor
struct NearbyScoreTests {
    let world = TestWorld()

    @Test func theScoreIsUnknownUntilTheFirstLoad() {
        #expect(NearbyViewModel(environment: world.environment).score == nil)
    }

    @Test func loadingShowsTheSignedInUsersScore() async throws {
        world.session.switchUser(to: DemoUsers.bea.id)
        let viewModel = NearbyViewModel(environment: world.environment)
        await viewModel.load()
        let summary = try await world.environment.kindness.kindnessSummary(for: DemoUsers.bea.id)
        #expect(viewModel.score == summary.lifetimePoints)
        #expect(viewModel.score == 90)
    }
}
