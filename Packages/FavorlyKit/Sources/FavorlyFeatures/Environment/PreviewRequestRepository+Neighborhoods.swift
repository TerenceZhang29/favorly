import FavorlyCore

extension PreviewRequestRepository: NeighborhoodDirectory {
    func neighborhoods(near _: GeoPoint) async throws -> [String] {
        ["Roosevelt Island", "Upper East Side", "Long Island City"]
    }
}
