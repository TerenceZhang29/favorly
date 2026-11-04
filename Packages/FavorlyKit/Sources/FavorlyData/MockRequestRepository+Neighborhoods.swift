import FavorlyCore

/// Neighborhood names from `DemoNeighborhoods`, like the server's `neighborhoods_near` around the demo places.
extension MockRequestRepository: NeighborhoodDirectory {
    public func neighborhoods(near point: GeoPoint) async throws -> [String] {
        try await beginOperation()
        return DemoNeighborhoods.names(near: point)
    }
}
