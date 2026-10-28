import Foundation

/// What the user has said about sharing their location with Favorly.
public enum LocationAuthorization: Equatable, Sendable {
    case notDetermined
    /// Denied, or restricted by parental controls or a device policy.
    case denied
    case allowed
}
