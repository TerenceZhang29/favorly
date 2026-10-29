import Foundation

/// The system's notification permission and registration.
@MainActor
public protocol NotificationService: AnyObject, Sendable {
    /// Asks for permission the first time only, then registers for notifications if allowed. Called after the
    /// user's first post or pick-up, when a notification is clearly useful, rather than at launch.
    func requestPermissionIfNeeded() async
    /// Registers again if permission was given, so a new device token reaches the server. Called at sign-in.
    func registerIfAllowed() async
}
