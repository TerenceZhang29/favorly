import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Testing

@MainActor
struct BlockedUsersViewModelTests {
    let world = TestWorld()

    @Test func listsTheBlockedPeopleAndUnblocks() async throws {
        try await world.repository.block(DemoUsers.bea.id, by: DemoUsers.alex.id)
        let viewModel = BlockedUsersViewModel(environment: world.environment)
        #expect(viewModel.state == .loading)
        await viewModel.load()
        #expect(viewModel.state == .loaded([DemoUsers.bea]))

        await viewModel.unblock(DemoUsers.bea)
        #expect(viewModel.state == .loaded([]))
        #expect(viewModel.actionError == nil)
    }
}
