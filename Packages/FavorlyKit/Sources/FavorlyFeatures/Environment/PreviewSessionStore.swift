import FavorlyCore
import Observation

@MainActor
@Observable
final class PreviewSessionStore: SessionStore, DemoSessionControls {
    let availableUsers: [UserProfile]
    private(set) var currentUser: UserProfile

    init(availableUsers: [UserProfile], currentUser: UserProfile) {
        self.availableUsers = availableUsers
        self.currentUser = currentUser
    }

    func profile(for id: UserID) -> UserProfile? {
        availableUsers.first { $0.id == id }
    }

    func switchUser(to id: UserID) {
        guard let user = profile(for: id) else { return }
        currentUser = user
    }
}
