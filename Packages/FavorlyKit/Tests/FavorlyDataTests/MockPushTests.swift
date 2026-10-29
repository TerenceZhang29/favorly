import FavorlyData
import Foundation
import Testing

@MainActor
struct MockPushTests {
    @Test func theRegistrarRemembersTheDeviceUntilUnregistered() async throws {
        let registrar = MockPushRegistrar()
        try await registrar.register(deviceToken: Data([0xAB, 0xCD]))
        #expect(await registrar.deviceToken == Data([0xAB, 0xCD]))
        await registrar.unregister()
        #expect(await registrar.deviceToken == nil)
    }

    @Test func theNotificationServiceCountsRequests() async {
        let service = MockNotificationService()
        await service.requestPermissionIfNeeded()
        await service.registerIfAllowed()
        await service.registerIfAllowed()
        #expect(service.permissionRequests == 1)
        #expect(service.registrations == 2)
    }
}
