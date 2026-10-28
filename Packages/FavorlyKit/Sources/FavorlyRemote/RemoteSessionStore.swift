import FavorlyCore
import Observation

/// The signed-in user, set by `RemoteAuthService`, and the profiles the directory has seen.
@MainActor
@Observable
public final class RemoteSessionStore: SessionStore {
    /// Stands in before anyone signs in; no screen that reads it is shown then.
    static let signedOutUser = UserProfile(id: UserID(rawValue: "signed-out"), displayName: "", neighborhood: "")

    public private(set) var currentUser = RemoteSessionStore.signedOutUser

    @ObservationIgnored private let directory: RemoteProfileDirectory

    public init(directory: RemoteProfileDirectory) {
        self.directory = directory
    }

    public func profile(for id: UserID) -> UserProfile? {
        id == currentUser.id ? currentUser : directory.profile(for: id)
    }

    func signIn(as user: UserProfile) {
        directory.remember(user)
        currentUser = user
    }

    func signOut() {
        currentUser = Self.signedOutUser
    }
}
