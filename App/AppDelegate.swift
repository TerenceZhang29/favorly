import FavorlyFeatures
import UIKit
import UserNotifications

/// Receives the device token and notification taps, which SwiftUI has no hooks for.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    /// Exists from launch, before SwiftUI builds the environment, so a notification tapped while the app was not
    /// running is kept until the tabs can open it. Every environment the app builds uses this router.
    @MainActor static let router = NotificationRouter()

    /// Set by `FavorlyApp` once its environment exists. A device token that arrived earlier is sent then.
    @MainActor var environment: AppEnvironment? {
        didSet {
            if let pendingToken {
                self.pendingToken = nil
                register(pendingToken)
            }
        }
    }

    @MainActor private var pendingToken: Data?

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in register(deviceToken) }
    }

    @MainActor private func register(_ deviceToken: Data) {
        guard let environment else {
            pendingToken = deviceToken
            return
        }
        Task { try? await environment.push.register(deviceToken: deviceToken) }
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
            Self.router.pending = route
        }
    }
}
