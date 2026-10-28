import FavorlyCore
@testable import FavorlyFeatures
import Testing

@MainActor
struct WelcomeViewModelTests {
    let world = TestWorld(startsSignedIn: false)

    @Test func signingInMovesOnToProfileSetup() async {
        let viewModel = WelcomeViewModel(environment: world.environment)
        #expect(!viewModel.isSigningIn)
        await viewModel.signIn()
        #expect(world.auth.state == .needsProfile)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isSigningIn)
    }

    @Test func aFailedSignInShowsTheMessage() async {
        let environment = world.environment
        let viewModel = WelcomeViewModel(environment: AppEnvironment(
            repository: environment.repository,
            kindness: environment.kindness,
            reviews: environment.reviews,
            chat: environment.chat,
            locationProvider: environment.locationProvider,
            session: environment.session,
            auth: FailingAuthService(),
            locationSettings: environment.locationSettings
        ))
        await viewModel.signIn()
        #expect(viewModel.errorMessage == "Something went wrong. Please try again.")
    }
}
