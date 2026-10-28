import Foundation

/// The signed-in user, and the profiles of other users the app has seen.
@MainActor
public protocol SessionStore: AnyObject, Sendable {
    var currentUser: UserProfile { get }
    /// Nil for a user the session does not know.
    func profile(for id: UserID) -> UserProfile?
}
