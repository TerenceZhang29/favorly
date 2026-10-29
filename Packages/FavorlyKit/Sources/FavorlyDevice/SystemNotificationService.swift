import FavorlyCore
import Foundation
import UserNotifications
#if canImport(UIKit)
    import UIKit
#endif

/// `UNUserNotificationCenter` behind `NotificationService`. The device token arrives in the app delegate.
@MainActor
public final class SystemNotificationService: NotificationService {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func requestPermissionIfNeeded() async {
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
        await registerIfAllowed()
    }

    public func registerIfAllowed() async {
        let status = await center.notificationSettings().authorizationStatus
        guard Self.allowsRegistering(status) else { return }
        #if canImport(UIKit)
            UIApplication.shared.registerForRemoteNotifications()
        #endif
    }

    nonisolated static func allowsRegistering(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral: true
        default: false
        }
    }
}
