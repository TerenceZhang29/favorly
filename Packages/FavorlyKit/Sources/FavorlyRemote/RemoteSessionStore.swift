import FavorlyCore
import Foundation
import Observation

/// The signed-in user, set by `RemoteAuthService`, and the profiles the directory has seen. The signed-in user is
/// also saved on the device, so a launch without a connection can still open the tabs.
@MainActor
@Observable
public final class RemoteSessionStore: SessionStore {
    /// Stands in before anyone signs in; no screen that reads it is shown then.
    static let signedOutUser = UserProfile(id: UserID(rawValue: "signed-out"), displayName: "", neighborhood: "")

    public private(set) var currentUser = RemoteSessionStore.signedOutUser

    static let savedUserKey = "favorly.signedInUser"

    @ObservationIgnored private let directory: RemoteProfileDirectory
    @ObservationIgnored private let defaults: UserDefaults

    public init(directory: RemoteProfileDirectory, defaults: UserDefaults = .standard) {
        self.directory = directory
        self.defaults = defaults
    }

    public func profile(for id: UserID) -> UserProfile? {
        id == currentUser.id ? currentUser : directory.profile(for: id)
    }

    /// The user saved by the last sign-in on this device, when it is `id`.
    func savedUser(for id: UserID) -> UserProfile? {
        guard let data = defaults.data(forKey: Self.savedUserKey),
              let user = try? JSONDecoder().decode(UserProfile.self, from: data),
              user.id == id
        else { return nil }
        return user
    }

    func signIn(as user: UserProfile) {
        directory.remember(user)
        currentUser = user
        defaults.set(try? JSONEncoder().encode(user), forKey: Self.savedUserKey)
    }

    func signOut() {
        currentUser = Self.signedOutUser
        defaults.removeObject(forKey: Self.savedUserKey)
    }
}
