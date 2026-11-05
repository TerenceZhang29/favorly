import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Testing

/// The other person in the chat header and the pinned request card, as in the Grove mockup.
/// The ladder request is Dana's, claimed by Chen.
@MainActor
struct ChatHeaderTests {
    let world = TestWorld()

    private func loaded(as user: UserProfile) async -> ChatViewModel {
        world.session.switchUser(to: user.id)
        let viewModel = ChatViewModel(requestID: TestWorld.ladderID, environment: world.environment)
        await viewModel.load()
        return viewModel
    }

    @Test func theHelperSeesTheRequesterAndWhoMarksItDone() async throws {
        let viewModel = await loaded(as: DemoUsers.chen)
        #expect(viewModel.otherName == "Dana")
        #expect(viewModel.isHelping)
        #expect(viewModel.roleText == "You're helping")
        #expect(viewModel.pointsRangeText == "+10 to +20 pts")
        #expect(viewModel.completionNote == "Dana marks it done when you're finished")
        let summary = try await world.environment.kindness.kindnessSummary(for: DemoUsers.dana.id)
        let favors = summary.completedFavors == 1 ? "1 favor done" : "\(summary.completedFavors) favors done"
        #expect(viewModel.otherScoreText == "\(summary.lifetimePoints) points · \(favors)")
    }

    @Test func theRequesterSeesTheHelperAndNoPoints() async {
        let viewModel = await loaded(as: DemoUsers.dana)
        #expect(viewModel.otherName == "Chen")
        #expect(!viewModel.isHelping)
        #expect(viewModel.roleText == "Helping you")
        #expect(viewModel.pointsRangeText == nil)
        #expect(viewModel.completionNote == "Mark it done on the request when Chen is finished")
    }

    @Test func nothingIsKnownBeforeLoading() {
        let viewModel = ChatViewModel(requestID: TestWorld.ladderID, environment: world.environment)
        #expect(viewModel.otherName == nil)
        #expect(viewModel.otherScoreText == nil)
        #expect(viewModel.completionNote == nil)
    }
}
