import AuthenticationServices
import FavorlyCore
import Observation

@MainActor
@Observable
final class WelcomeViewModel {
    private(set) var isSigningIn = false
    /// Why the last sign-in failed.
    private(set) var errorMessage: String?

    @ObservationIgnored private let environment: AppEnvironment
    /// The raw nonce of the Sign in with Apple request in progress.
    @ObservationIgnored private var nonce: String?

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    /// The real backend shows Apple's button; the demo signs in with a plain one.
    var usesAppleSignIn: Bool {
        environment.auth.usesAppleSignIn
    }

    /// Demo and UI-test sign-in, which needs no Apple credential.
    func signIn() async {
        await signIn(identityToken: "", nonce: "")
    }

    /// Starts a Sign in with Apple request and returns the hashed nonce Apple's request carries.
    func appleRequestNonce() -> String {
        let nonce = AppleSignInNonce.make()
        self.nonce = nonce
        return AppleSignInNonce.sha256(nonce)
    }

    /// Apple returned a credential; the token and the raw nonce sign in to the server.
    func finishAppleSignIn(identityToken: Data?) async {
        guard let identityToken, let token = String(data: identityToken, encoding: .utf8), let nonce else {
            errorMessage = ErrorMessage.text(for: FavorlyError.notSignedIn)
            return
        }
        self.nonce = nil
        await signIn(identityToken: token, nonce: nonce)
    }

    /// Apple's sheet failed or was dismissed. Dismissing is not an error worth showing.
    func failAppleSignIn(_ error: any Error) {
        nonce = nil
        if (error as? ASAuthorizationError)?.code == .canceled {
            return
        }
        errorMessage = ErrorMessage.text(for: FavorlyError.notSignedIn)
    }

    private func signIn(identityToken: String, nonce: String) async {
        guard !isSigningIn else { return }
        isSigningIn = true
        defer { isSigningIn = false }
        errorMessage = nil

        do {
            try await environment.auth.signInWithApple(identityToken: identityToken, nonce: nonce)
        } catch is CancellationError {
            // The screen went away.
        } catch {
            errorMessage = ErrorMessage.text(for: error)
        }
    }
}
