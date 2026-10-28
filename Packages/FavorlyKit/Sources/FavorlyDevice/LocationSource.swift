import FavorlyCore
import Foundation

/// The device's permission and position. `CoreLocationSource` is the real one; tests use a fake.
@MainActor
public protocol LocationSource: AnyObject {
    var authorization: LocationAuthorization { get }
    /// Shows the system prompt if the user has not answered yet, and returns their answer.
    func requestAuthorization() async -> LocationAuthorization
    /// One position fix.
    func currentPoint() async throws -> GeoPoint
}
