import FavorlyCore
import Foundation

/// Names the neighborhood around a point, such as "Roosevelt Island". `GeocoderNeighborhoodNamer` is the real one.
public protocol NeighborhoodNamer: Sendable {
    /// Nil when no name is known, or the lookup failed.
    func name(for point: GeoPoint) async -> String?
}
