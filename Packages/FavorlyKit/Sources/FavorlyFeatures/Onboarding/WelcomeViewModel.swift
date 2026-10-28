import FavorlyCore
import Observation

@MainActor
@Observable
final class WelcomeViewModel {
    private(set) var isSigningIn = false
    /// Why the last sign-in failed.
    private(set) var errorMessage: String?

    @ObservationIgnored private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    /// Phase 4C passes Sign in with Apple's token and nonce here; until then the mock needs neither.
    func signIn() async {
        guard !isSigningIn else { return }
        isSigningIn = true
        defer { isSigningIn = false }
        errorMessage = nil

        do {
            try await environment.auth.signInWithApple(identityToken: "", nonce: "")
        } catch is CancellationError {
            // The screen went away.
        } catch {
            errorMessage = ErrorMessage.text(for: error)
        }
    }
}
