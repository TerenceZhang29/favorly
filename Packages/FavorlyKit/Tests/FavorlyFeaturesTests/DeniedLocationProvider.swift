import FavorlyCore

/// The device's location when the user said no.
struct DeniedLocationProvider: LocationProvider {
    func currentLocation() async throws -> TaggedLocation {
        throw FavorlyError.locationPermissionDenied
    }
}
