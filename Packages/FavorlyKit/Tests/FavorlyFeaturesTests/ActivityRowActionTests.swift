import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Testing

/// The row actions and points on My Activity, as in the Grove mockup.
@MainActor
struct ActivityRowActionTests {
    let world = TestWorld()
    let viewModel: ActivityViewModel

    init() {
        viewModel = ActivityViewModel(environment: world.environment)
    }

    private func load(as user: UserProfile, _ segment: ActivitySegment) async -> [HelpRequest] {
        world.session.switchUser(to: user.id)
        await viewModel.load()
        viewModel.segment = segment
        return viewModel.items ?? []
    }

    @Test func theRequesterOfAClaimedRequestCanMessageAndComplete() async throws {
        let ladder = try #require(await load(as: DemoUsers.dana, .posted).first { $0.id == TestWorld.ladderID })
        #expect(ladder.status == .claimed)
        #expect(viewModel.canMessage(ladder))
        #expect(viewModel.canComplete(ladder))
        #expect(!viewModel.canReview(ladder))
        #expect(viewModel.earnedPointsText(for: ladder) == nil)
    }

    @Test func theHelperCanMessageButNotComplete() async throws {
        let ladder = try #require(await load(as: DemoUsers.chen, .pickedUp).first { $0.id == TestWorld.ladderID })
        #expect(viewModel.canMessage(ladder))
        #expect(!viewModel.canComplete(ladder))
    }

    @Test func helpedFavorsShowTheirPoints() async throws {
        let completed = await load(as: DemoUsers.bea, .pickedUp).filter { $0.status == .completed }
        #expect(!completed.isEmpty)
        for request in completed {
            let review = try await world.environment.reviews.review(for: request.id)
            let points = KindnessRules.pointsPerFavor + KindnessRules.pointsPerStar * (review?.rating ?? 0)
            #expect(viewModel.earnedPointsText(for: request) == "+\(points) pts")
        }
    }

    @Test func onlyAnUnreviewedCompletedRequestOffersAReview() async throws {
        let completed = await load(as: DemoUsers.dana, .posted).filter { $0.status == .completed }
        #expect(!completed.isEmpty)
        for request in completed {
            let reviewed = try await world.environment.reviews.review(for: request.id) != nil
            #expect(viewModel.canReview(request) == (!reviewed && request.helperID != nil))
            #expect(!viewModel.canMessage(request))
        }
    }

    @Test func completingFromTheRowUpdatesTheList() async throws {
        let ladder = try #require(await load(as: DemoUsers.dana, .posted).first { $0.id == TestWorld.ladderID })
        await viewModel.complete(ladder)
        #expect(viewModel.actionError == nil)
        #expect(viewModel.items?.first { $0.id == TestWorld.ladderID }?.status == .completed)
    }

    @Test func aFailedCompletionShowsItsMessage() async throws {
        let ladder = try #require(await load(as: DemoUsers.chen, .pickedUp).first { $0.id == TestWorld.ladderID })
        await viewModel.complete(ladder)
        #expect(viewModel.actionError == ErrorMessage.text(for: FavorlyError.notAllowed))
    }
}
