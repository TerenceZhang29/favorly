import AuthenticationServices
import FavorlyCore
@testable import FavorlyFeatures
import Foundation
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
            moderation: environment.moderation,
            locationProvider: environment.locationProvider,
            session: environment.session,
            auth: FailingAuthService(),
            push: environment.push,
            notifications: environment.notifications,
            locationSettings: environment.locationSettings
        ))
        await viewModel.signIn()
        #expect(viewModel.errorMessage == "Something went wrong. Please try again.")
    }

    // MARK: Sign in with Apple

    @Test func theDemoUsesThePlainButton() {
        #expect(!WelcomeViewModel(environment: world.environment).usesAppleSignIn)
    }

    @Test func eachAppleRequestGetsAFreshHashedNonce() {
        let viewModel = WelcomeViewModel(environment: world.environment)
        let first = viewModel.appleRequestNonce()
        let second = viewModel.appleRequestNonce()
        #expect(first.count == 64)
        let isHex = first.allSatisfy(\.isHexDigit)
        #expect(isHex)
        #expect(first != second)
    }

    @Test func theNonceHashIsSHA256() {
        #expect(AppleSignInNonce.sha256("abc")
            == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        #expect(AppleSignInNonce.make().count == 32)
    }

    @Test func anAppleCredentialSignsIn() async {
        let viewModel = WelcomeViewModel(environment: world.environment)
        _ = viewModel.appleRequestNonce()
        await viewModel.finishAppleSignIn(identityToken: Data("header.payload.signature".utf8))
        #expect(world.auth.state == .needsProfile)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func aCredentialWithoutATokenShowsAnError() async {
        let viewModel = WelcomeViewModel(environment: world.environment)
        _ = viewModel.appleRequestNonce()
        await viewModel.finishAppleSignIn(identityToken: nil)
        #expect(world.auth.state == .signedOut)
        #expect(viewModel.errorMessage == "Please sign in again.")
    }

    @Test func dismissingApplesSheetIsNotAnError() {
        let viewModel = WelcomeViewModel(environment: world.environment)
        viewModel.failAppleSignIn(ASAuthorizationError(.canceled))
        #expect(viewModel.errorMessage == nil)
        viewModel.failAppleSignIn(ASAuthorizationError(.failed))
        #expect(viewModel.errorMessage == "Please sign in again.")
    }
}
