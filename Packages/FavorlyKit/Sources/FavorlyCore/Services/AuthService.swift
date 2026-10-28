import Foundation

/// Signing in, signing up, signing out and deleting the account.
@MainActor
public protocol AuthService: AnyObject, Sendable {
    var state: AuthState { get }
    /// True when signing in needs a Sign in with Apple credential; the demo and preview services need none.
    var usesAppleSignIn: Bool { get }
    /// Signs in with the token Sign in with Apple returned. A user who is new to Favorly then needs a profile.
    func signInWithApple(identityToken: String, nonce: String) async throws
    /// Finishes sign-up. Throws `FavorlyError.validation` when `ProfileSetupRules` refuses the draft.
    func completeProfile(_ draft: ProfileSetupDraft) async throws
    func signOut() async
    /// Deletes the account, then signs out.
    func deleteAccount() async throws
}
