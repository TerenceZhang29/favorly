import FavorlyCore
import Observation

/// Starts signed in and moves between states at once, so previews can show every sign-in screen.
@MainActor
@Observable
final class PreviewAuthService: AuthService {
    private(set) var state: AuthState
    let usesAppleSignIn = false

    init(state: AuthState = .signedIn) {
        self.state = state
    }

    func signInWithApple(identityToken _: String, nonce _: String) async throws {
        state = .needsProfile
    }

    func completeProfile(_ draft: ProfileSetupDraft) async throws {
        try ProfileSetupRules.validate(draft)
        state = .signedIn
    }

    func signOut() async {
        state = .signedOut
    }

    func deleteAccount() async throws {
        state = .signedOut
    }
}
