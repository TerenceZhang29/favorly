import Foundation

/// The neighborhood names a request at a point may carry, so a request on Roosevelt Island can't claim "Seattle".
public protocol NeighborhoodDirectory: Sendable {
    /// The names around `point`, best first; at most 8. Empty where the directory has no data (outside NYC), and
    /// then any label that passes `DraftValidator` is accepted.
    func neighborhoods(near point: GeoPoint) async throws -> [String]
}
