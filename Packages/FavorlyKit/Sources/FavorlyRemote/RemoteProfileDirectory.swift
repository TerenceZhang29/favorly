import FavorlyCore
import Foundation
import Observation
import Supabase

/// The profiles the app has seen, so screens can show names without waiting. The repository fills it after
/// every read that names people.
@MainActor
@Observable
public final class RemoteProfileDirectory {
    private(set) var profiles: [UserID: UserProfile] = [:]

    @ObservationIgnored private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    func profile(for id: UserID) -> UserProfile? {
        profiles[id]
    }

    func remember(_ profile: UserProfile) {
        profiles[profile.id] = profile
    }

    func forget(_ id: UserID) {
        profiles[id] = nil
    }

    /// Fetches the profiles it does not know yet. A failure leaves them out, so names fall back to "A neighbor".
    func load(_ ids: Set<UserID>) async {
        let missing = ids.filter { profiles[$0] == nil }.compactMap(\.remoteID)
        guard !missing.isEmpty else { return }
        do {
            let rows: [ProfileRow] = try await client.from("profiles")
                .select("id, display_name, neighborhood")
                .in("id", values: missing)
                .execute()
                .value
            for row in rows {
                remember(row.model())
            }
        } catch {
            // Names are a nicety; the screen still works without them.
        }
    }
}
