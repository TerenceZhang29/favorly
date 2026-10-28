import FavorlyCore
import Foundation
import Observation

/// Sign-in without Apple or a server: every sign-in is a new user, who becomes a session user once they finish
/// their profile.
@MainActor
@Observable
public final class MockAuthService: AuthService {
    public private(set) var state: AuthState
    public let usesAppleSignIn = false

    @ObservationIgnored private let session: MockSessionStore
    @ObservationIgnored private let artificialDelay: Duration

    /// - Parameters:
    ///   - startsSignedIn: True to start as the session's current user, as the demo and UI tests do.
    ///   - artificialDelay: Wait before each action, so loading states are visible.
    public init(session: MockSessionStore, startsSignedIn: Bool, artificialDelay: Duration = .milliseconds(300)) {
        self.session = session
        self.artificialDelay = artificialDelay
        state = startsSignedIn ? .signedIn : .signedOut
    }

    /// Ignores the token: the mock treats everyone as new to Favorly.
    public func signInWithApple(identityToken _: String, nonce _: String) async throws {
        try await simulateLatency()
        state = .needsProfile
    }

    public func completeProfile(_ draft: ProfileSetupDraft) async throws {
        try await simulateLatency()
        guard state == .needsProfile else { throw FavorlyError.notAllowed }
        let draft = try ProfileSetupRules.validate(draft)
        let user = UserProfile(
            id: UserID(rawValue: "user-\(UUID().uuidString.lowercased())"),
            displayName: draft.displayName,
            neighborhood: ""
        )
        session.signIn(as: user)
        state = .signedIn
    }

    public func signOut() async {
        state = .signedOut
    }

    /// Forgets the user in the session. Their requests, messages and reviews stay in the mock repository.
    public func deleteAccount() async throws {
        try await simulateLatency()
        guard state == .signedIn else { throw FavorlyError.notAllowed }
        session.forget(session.currentUser.id)
        state = .signedOut
    }

    private func simulateLatency() async throws {
        guard artificialDelay > .zero else { return }
        try await Task.sleep(for: artificialDelay)
    }
}
