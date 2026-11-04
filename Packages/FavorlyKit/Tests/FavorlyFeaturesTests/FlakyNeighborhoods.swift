import FavorlyCore

/// Fails with `.network` until `recover()`, then offers Roosevelt Island.
actor FlakyNeighborhoods: NeighborhoodDirectory {
    private var isDown = true

    func recover() {
        isDown = false
    }

    func neighborhoods(near _: GeoPoint) async throws -> [String] {
        if isDown {
            throw FavorlyError.network
        }
        return ["Roosevelt Island"]
    }
}
