import FavorlyCore
import Foundation

/// Fails every action, for the error paths of the sign-in screens.
@MainActor
final class FailingAuthService: AuthService {
    struct Failure: Error {}

    private(set) var state = AuthState.signedOut
    let usesAppleSignIn = false

    func signInWithApple(identityToken _: String, nonce _: String) async throws {
        throw Failure()
    }

    func completeProfile(_: ProfileSetupDraft) async throws {
        throw Failure()
    }

    func signOut() async {}

    func deleteAccount() async throws {
        throw Failure()
    }
}
