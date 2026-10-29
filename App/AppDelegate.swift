import FavorlyFeatures
import UIKit
import UserNotifications

/// Receives the device token and notification taps, which SwiftUI has no hooks for.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    /// Set by `FavorlyApp` once its environment exists.
    @MainActor var environment: AppEnvironment?

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            try? await environment?.push.register(deviceToken: deviceToken)
        }
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: any Error) {
        // No notifications on this device; the app works without them.
    }

    /// Shows notifications as banners while the app is open too.
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    /// A tapped notification opens its request, or its chat for a message.
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let route = NotificationRoute(userInfo: response.notification.request.content.userInfo)
        await MainActor.run {
            environment?.router.pending = route
        }
    }
}
