import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Testing

@MainActor
struct ProfileSetupViewModelTests {
    let world = TestWorld(startsSignedIn: false)

    /// Signed in with Apple and on the setup screen.
    private func makeViewModel() async throws -> ProfileSetupViewModel {
        try await world.auth.signInWithApple(identityToken: "", nonce: "")
        return ProfileSetupViewModel(environment: world.environment)
    }

    @Test func startsEmptyAndCannotContinue() async throws {
        let viewModel = try await makeViewModel()
        #expect(viewModel.displayName.isEmpty)
        #expect(!viewModel.confirmedAdult)
        #expect(!viewModel.acceptedTerms)
        #expect(viewModel.nameMessage == nil)
        #expect(!viewModel.canContinue)
    }

    @Test func theNameMessageAppearsOnceTyping() async throws {
        let viewModel = try await makeViewModel()
        viewModel.displayName = "S"
        #expect(viewModel.nameMessage == "Name must be at least 2 characters.")
        viewModel.displayName = "Sam"
        #expect(viewModel.nameMessage == nil)
    }

    @Test func continuingNeedsANameAndBothBoxes() async throws {
        let viewModel = try await makeViewModel()
        viewModel.displayName = "Sam"
        #expect(!viewModel.canContinue)
        viewModel.confirmedAdult = true
        #expect(!viewModel.canContinue)
        viewModel.acceptedTerms = true
        #expect(viewModel.canContinue)
        viewModel.confirmedAdult = false
        #expect(!viewModel.canContinue)
    }

    @Test func submittingSignsInAsTheNewUser() async throws {
        let viewModel = try await makeViewModel()
        viewModel.displayName = " Sam "
        viewModel.confirmedAdult = true
        viewModel.acceptedTerms = true
        await viewModel.submit()

        #expect(world.auth.state == .signedIn)
        #expect(world.session.currentUser.displayName == "Sam")
        #expect(viewModel.submitError == nil)
        #expect(!viewModel.isSubmitting)
    }

    @Test func submittingAnIncompleteProfileDoesNothing() async throws {
        let viewModel = try await makeViewModel()
        viewModel.displayName = "Sam"
        await viewModel.submit()
        #expect(world.auth.state == .needsProfile)
        #expect(world.session.currentUser == DemoUsers.alex)
    }

    @Test func aFailedSubmitShowsTheMessage() async throws {
        let viewModel = try await makeViewModel()
        viewModel.displayName = "Sam"
        viewModel.confirmedAdult = true
        viewModel.acceptedTerms = true
        // Cancelled in another window, so there is no sign-in left to finish.
        await world.auth.signOut()
        await viewModel.submit()
        #expect(viewModel.submitError == "You're not allowed to do that.")
    }

    @Test func cancellingReturnsToWelcome() async throws {
        let viewModel = try await makeViewModel()
        await viewModel.cancel()
        #expect(world.auth.state == .signedOut)
    }
}
