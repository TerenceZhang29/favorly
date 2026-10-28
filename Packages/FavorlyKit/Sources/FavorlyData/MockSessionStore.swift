import FavorlyCore
import Observation

@MainActor
@Observable
public final class MockSessionStore: SessionStore, DemoSessionControls {
    public private(set) var availableUsers: [UserProfile]
    public private(set) var currentUser: UserProfile

    public init(availableUsers: [UserProfile] = DemoUsers.all, currentUser: UserProfile = DemoUsers.alex) {
        self.availableUsers = availableUsers
        self.currentUser = currentUser
    }

    public func profile(for id: UserID) -> UserProfile? {
        availableUsers.first { $0.id == id }
    }

    /// Does nothing if `id` is not one of `availableUsers`.
    public func switchUser(to id: UserID) {
        guard let user = profile(for: id) else { return }
        currentUser = user
    }

    /// Adds a user who just signed up and makes them the current user.
    func signIn(as user: UserProfile) {
        availableUsers.append(user)
        currentUser = user
    }

    /// Forgets a deleted user. The current user stays as it was until someone signs in again.
    func forget(_ id: UserID) {
        availableUsers.removeAll { $0.id == id }
    }
}
