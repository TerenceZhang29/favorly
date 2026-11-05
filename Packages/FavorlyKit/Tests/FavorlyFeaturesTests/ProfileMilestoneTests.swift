import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Testing

/// The milestone ring and card, and the points on past activities, as in the Grove mockup.
@MainActor
struct ProfileMilestoneTests {
    let world = TestWorld()

    private func loadedProfile(of user: UserProfile) async -> ProfileViewModel {
        world.session.switchUser(to: user.id)
        let viewModel = ProfileViewModel(environment: world.environment)
        await viewModel.load()
        return viewModel
    }

    @Test func beaIsNinetyPointsIntoHerFirstMilestone() async {
        let viewModel = await loadedProfile(of: DemoUsers.bea)
        #expect(viewModel.milestonePoints == 90)
        #expect(viewModel.milestoneProgress == 0.9)
        #expect(viewModel.milestoneText == "90 of 100 points")
        #expect(viewModel.milestoneRemainingText == "10 more points to go")
    }

    @Test func aNewUserStartsAtZero() async {
        let viewModel = await loadedProfile(of: DemoUsers.alex)
        #expect(viewModel.milestonePoints == 0)
        #expect(viewModel.milestoneRemainingText == "100 more points to go")
    }

    @Test func helpedActivitiesShowTheirPointsAndAskedOnesDont() async throws {
        let viewModel = await loadedProfile(of: DemoUsers.bea)
        let activities = try #require(viewModel.content?.activities)
        #expect(!activities.isEmpty)
        for activity in activities {
            switch activity.role {
            case .helped:
                let stars = viewModel.content?.reviews.first { $0.requestID == activity.id }?.rating ?? 0
                #expect(viewModel.pointsText(for: activity) == "+\(10 + 2 * stars)")
            case .asked:
                #expect(viewModel.pointsText(for: activity) == nil)
            }
        }
    }
}
