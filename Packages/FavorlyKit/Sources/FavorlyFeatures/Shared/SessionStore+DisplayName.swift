import FavorlyCore

extension SessionStore {
    func displayName(for id: UserID) -> String {
        profile(for: id)?.displayName ?? "A neighbor"
    }
}
