import FavorlyCore
import Supabase

/// The server's `neighborhoods_near`, which `create_request` checks the neighborhood against.
extension RemoteRepository: NeighborhoodDirectory {
    public func neighborhoods(near point: GeoPoint) async throws -> [String] {
        let params: [String: AnyJSON] = [
            "latitude": .double(point.latitude),
            "longitude": .double(point.longitude),
        ]
        return try await call { try await client.rpc("neighborhoods_near", params: params).execute().value }
    }
}
