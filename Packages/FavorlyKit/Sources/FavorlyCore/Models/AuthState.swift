import Foundation

/// Where the user is in signing in. Screens behind sign-in read the user from `SessionStore`.
public enum AuthState: Equatable, Sendable {
    /// At launch, while a session saved by an earlier launch is checked. Shows neither Welcome nor the tabs.
    case restoring
    case signedOut
    /// Signed in with Apple, but has not chosen a name or accepted the terms yet.
    case needsProfile
    case signedIn
}
