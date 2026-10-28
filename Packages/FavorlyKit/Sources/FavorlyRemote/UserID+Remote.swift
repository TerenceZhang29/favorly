import FavorlyCore
import Foundation

extension UserID {
    /// Stands in for someone who deleted their account; no profile has this ID, so names read "A neighbor".
    static let deletedUser = UserID(rawValue: "deleted-user")

    /// Server user IDs are UUIDs, stored lowercased so they compare equal to the ones in the session.
    init(remote id: UUID) {
        self.init(rawValue: id.uuidString.lowercased())
    }

    /// The UUID behind a server user ID, or nil for a demo ID such as "user-alex".
    var remoteID: UUID? {
        UUID(uuidString: rawValue)
    }
}
