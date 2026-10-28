import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Testing

@MainActor
struct ReportViewModelTests {
    let world = TestWorld()

    @Test func sendingNeedsAReason() {
        let viewModel = ReportViewModel(target: .request(TestWorld.eggsID), environment: world.environment)
        #expect(viewModel.title == "Report request")
        #expect(!viewModel.canSend)
        viewModel.reason = .spam
        #expect(viewModel.canSend)
    }

    @Test func aSentReportReachesTheRepositoryAndCannotBeSentTwice() async {
        let viewModel = ReportViewModel(target: .user(DemoUsers.bea.id), environment: world.environment)
        viewModel.reason = .unsafe
        viewModel.note = " Asked for my address "
        await viewModel.send()

        #expect(viewModel.didSend)
        #expect(!viewModel.canSend)
        let expected = MockReport(
            target: .user(DemoUsers.bea.id), reason: .unsafe, note: "Asked for my address",
            reporterID: DemoUsers.alex.id
        )
        #expect(await world.repository.submittedReports() == [expected])
    }

    @Test func aFailedReportShowsTheMessage() async {
        let viewModel = ReportViewModel(target: .user(DemoUsers.alex.id), environment: world.environment)
        viewModel.reason = .other
        await viewModel.send()
        #expect(!viewModel.didSend)
        #expect(viewModel.sendError == "You're not allowed to do that.")
    }

    @Test func aLongNoteBlocksSending() {
        let viewModel = ReportViewModel(target: .request(TestWorld.eggsID), environment: world.environment)
        viewModel.reason = .spam
        viewModel.note = String(repeating: "a", count: 501)
        #expect(!viewModel.canSend)
    }

    @Test func titlesNameWhatIsReported() {
        #expect(ReportViewModel(target: .user(DemoUsers.bea.id), environment: world.environment)
            .title == "Report person")
        #expect(ReportReason.unsafe.title == "Unsafe or threatening")
    }
}
