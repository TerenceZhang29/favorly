import Observation

/// Hands a tapped notification to the tabs, which open it in My Activity.
@MainActor
@Observable
public final class NotificationRouter {
    /// The notification waiting to be opened; the tabs clear it once they have.
    public var pending: NotificationRoute?

    public init() {}
}
