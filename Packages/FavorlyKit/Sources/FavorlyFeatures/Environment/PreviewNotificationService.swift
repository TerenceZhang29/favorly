import FavorlyCore

/// Previews never ask for permission.
@MainActor
final class PreviewNotificationService: NotificationService {
    func requestPermissionIfNeeded() async {}

    func registerIfAllowed() async {}
}
