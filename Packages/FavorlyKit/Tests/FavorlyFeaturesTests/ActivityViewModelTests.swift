import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Testing

@MainActor
struct ActivityViewModelTests {
    let world = TestWorld()
    let viewModel: ActivityViewModel

    init() {
        viewModel = ActivityViewModel(environment: world.environment)
    }

    private func items(_ segment: ActivitySegment, as user: UserProfile) async -> [HelpRequest] {
        world.session.switchUser(to: user.id)
        await viewModel.load()
        viewModel.segment = segment
        return viewModel.items ?? []
    }

    @Test func startsLoadingOnMyRequests() {
        #expect(viewModel.state == .loading)
        #expect(viewModel.segment == .posted)
        #expect(viewModel.items == nil)
    }

    @Test func alexStartsWithNothingInEitherSegment() async {
        await viewModel.load()
        #expect(viewModel.items == [])
        viewModel.segment = .pickedUp
        #expect(viewModel.items == [])
        #expect(ActivitySegment.posted.emptyMessage != ActivitySegment.pickedUp.emptyMessage)
    }

    @Test func segmentsListTheRightItemsPerUser() async {
        let chenPosted = await items(.posted, as: DemoUsers.chen)
        #expect(chenPosted.count == 6)
        #expect(chenPosted.allSatisfy { $0.requesterID == DemoUsers.chen.id })
        #expect(await items(.pickedUp, as: DemoUsers.chen).map(\.id) == [TestWorld.ladderID, TestWorld.seedID(17)])

        let beaPosted = await items(.posted, as: DemoUsers.bea)
        #expect(beaPosted.count == 4)
        #expect(beaPosted.allSatisfy { $0.requesterID == DemoUsers.bea.id })
        #expect(await items(.pickedUp, as: DemoUsers.bea).map(\.status) == Array(repeating: .completed, count: 5))
    }

    @Test func myRequestsAreNewestFirst() async {
        let posted = await items(.posted, as: DemoUsers.dana)
        #expect(posted.map(\.createdAt) == posted.map(\.createdAt).sorted(by: >))
    }

    @Test func reloadKeyFollowsTheCurrentUser() {
        #expect(viewModel.reloadKey == DemoUsers.alex.id)
        world.session.switchUser(to: DemoUsers.bea.id)
        #expect(viewModel.reloadKey == DemoUsers.bea.id)
    }

    @Test func subtitleShowsStatusAndWhoPostedSomeoneElsesRequest() async throws {
        let ladderAsRequester = try #require(await items(.posted, as: DemoUsers.dana)
            .first { $0.id == TestWorld.ladderID })
        #expect(viewModel.subtitle(for: ladderAsRequester) == "Claimed by Chen")

        let ladderAsHelper = try #require(await items(.pickedUp, as: DemoUsers.chen).first)
        #expect(viewModel.subtitle(for: ladderAsHelper) == "Claimed by Chen · Posted by Dana")

        let saffron = try #require(await items(.pickedUp, as: DemoUsers.bea).first)
        #expect(viewModel.subtitle(for: saffron) == "Completed · Posted by Dana")
    }

    @Test func aNewRequestAndItsPickUpAppearWithoutAManualRefresh() async throws {
        await viewModel.load()
        let observing = Task { await viewModel.observeChanges() }
        defer { observing.cancel() }
        await Task.yield()

        let draft = NewRequestDraft(
            title: "Need a cup of rice",
            details: "",
            category: .ingredient,
            location: TaggedLocation(point: LocationPresets.cornellTech.location.point, label: "Roosevelt Island")
        )
        let created = try await world.repository.create(draft, by: DemoUsers.alex.id)
        #expect(await TestWorld.eventually { viewModel.items?.map(\.id) == [created.id] })
        #expect(viewModel.subtitle(for: created) == "Open")

        _ = try await world.repository.claim(created.id, by: DemoUsers.bea.id)
        #expect(await TestWorld.eventually { viewModel.items?.first?.status == .claimed })
        let claimed = try #require(viewModel.items?.first)
        #expect(viewModel.subtitle(for: claimed) == "Claimed by Bea")
    }

    @Test func pickingUpARequestMovesItIntoPickedUpByMe() async throws {
        world.session.switchUser(to: DemoUsers.bea.id)
        _ = try await world.repository.claim(TestWorld.eggsID, by: DemoUsers.bea.id)
        await viewModel.load()
        viewModel.segment = .pickedUp
        #expect(viewModel.items?.first?.id == TestWorld.eggsID)
        #expect(viewModel.items?.count == 6)
    }
}
