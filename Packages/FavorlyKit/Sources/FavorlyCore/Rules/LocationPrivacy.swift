import Foundation

/// How exact a location Favorly keeps and shares.
public enum LocationPrivacy {
    /// Decimal places kept: 3 is about 110 m of latitude, the same snapping the server applies.
    public static let decimalPlaces = 3

    /// Rounds a point to about 100 m, so nobody can find an exact address from it.
    public static func snapped(_ point: GeoPoint) -> GeoPoint {
        GeoPoint(latitude: round(point.latitude), longitude: round(point.longitude))
    }

    private static func round(_ degrees: Double) -> Double {
        let scale = pow(10, Double(decimalPlaces))
        return (degrees * scale).rounded() / scale
    }
}
