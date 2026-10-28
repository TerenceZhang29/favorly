import FavorlyCore
import Foundation

struct ProfileRow: Decodable, Sendable {
    let id: UUID
    let displayName: String
    let neighborhood: String

    enum CodingKeys: String, CodingKey {
        case id, neighborhood
        case displayName = "display_name"
    }

    func model() -> UserProfile {
        UserProfile(id: UserID(remote: id), displayName: displayName, neighborhood: neighborhood)
    }
}
