import FavorlyCore
import Foundation

/// The device's location, snapped to about 100 m and named by neighborhood. Asks for permission the first time
/// a screen needs a location, which is when Nearby or Post first loads.
@MainActor
public final class DeviceLocationProvider: LocationProvider {
    /// Shown when no neighborhood name is known for a point.
    static let fallbackLabel = "Your neighborhood"

    private let source: any LocationSource
    private let namer: any NeighborhoodNamer
    /// The last named point, so moving within the same 100 m square does not look the name up again.
    private var lastNamed: TaggedLocation?

    public init(source: any LocationSource, namer: any NeighborhoodNamer) {
        self.source = source
        self.namer = namer
    }

    public func currentLocation() async throws -> TaggedLocation {
        var authorization = source.authorization
        if authorization == .notDetermined {
            authorization = await source.requestAuthorization()
        }
        guard authorization == .allowed else { throw FavorlyError.locationPermissionDenied }

        let point: GeoPoint
        do {
            point = try await LocationPrivacy.snapped(source.currentPoint())
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw FavorlyError.locationUnavailable
        }

        if let lastNamed, lastNamed.point == point {
            return lastNamed
        }
        let location = await TaggedLocation(point: point, label: namer.name(for: point) ?? Self.fallbackLabel)
        lastNamed = location
        return location
    }
}
