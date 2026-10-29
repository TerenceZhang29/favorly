@testable import FavorlyDevice
import Testing
import UserNotifications

struct SystemNotificationServiceTests {
    @Test func onlyAllowedStatusesRegister() {
        #expect(SystemNotificationService.allowsRegistering(.authorized))
        #expect(SystemNotificationService.allowsRegistering(.provisional))
        #expect(!SystemNotificationService.allowsRegistering(.denied))
        #expect(!SystemNotificationService.allowsRegistering(.notDetermined))
    }
}
