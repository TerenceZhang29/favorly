import CoreLocation
import FavorlyCore
import Foundation

/// Names a point with the system geocoder: the neighborhood (`subLocality`), else the city.
public struct GeocoderNeighborhoodNamer: NeighborhoodNamer {
    public init() {}

    public func name(for point: GeoPoint) async -> String? {
        let location = CLLocation(latitude: point.latitude, longitude: point.longitude)
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else { return nil }
        return Self.name(subLocality: placemark.subLocality, locality: placemark.locality)
    }

    static func name(subLocality: String?, locality: String?) -> String? {
        [subLocality, locality].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.first { !$0.isEmpty }
    }
}
