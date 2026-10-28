import FavorlyCore
import Foundation
import Supabase

extension RemoteRepository: KindnessRepository {
    public func kindnessSummary(for user: UserID) async throws -> KindnessSummary {
        guard let id = user.remoteID else { throw FavorlyError.notFound }
        let rows: [KindnessRow] = try await call {
            try await client.rpc("kindness_summary", params: ["user_id": AnyJSON.string(id.uuidString)]).execute().value
        }
        guard let row = rows.first else { throw FavorlyError.notFound }
        return row.model()
    }

    /// Gift cards are not part of 1.0 (phase 4A), so there are none.
    public func redemptions(by _: UserID) async throws -> [Redemption] {
        []
    }

    public func redeemGiftCard(by _: UserID) async throws -> Redemption {
        throw FavorlyError.notAllowed
    }
}
