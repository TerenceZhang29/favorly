import Observation

/// Hands a tapped notification to the tabs, which open it, and tells them when a message notification arrives
/// while the app is open, so the in-app banner can show it instead of the system one.
@MainActor
@Observable
public final class NotificationRouter {
    /// The notification waiting to be opened; the tabs clear it once they have.
    public var pending: NotificationRoute?

    /// Goes up by one for each message notification that arrives while the app is in the foreground.
    public private(set) var foregroundMessages = 0

    public init() {}

    public func messageArrivedInForeground() {
        foregroundMessages += 1
    }
}
