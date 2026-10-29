import FavorlyCore
import Observation

/// Counts what was asked, without the system's prompt.
@MainActor
@Observable
public final class MockNotificationService: NotificationService {
    public private(set) var permissionRequests = 0
    public private(set) var registrations = 0

    public init() {}

    public func requestPermissionIfNeeded() async {
        permissionRequests += 1
    }

    public func registerIfAllowed() async {
        registrations += 1
    }
}
