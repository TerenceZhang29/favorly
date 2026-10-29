import FavorlyCore
@testable import FavorlyFeatures
import Foundation
import Testing

struct NotificationRouteTests {
    static let id = "5a3dac11-dd4c-453a-a9c5-1f88f82693ef"
    static let requestID = RequestID(rawValue: UUID(uuidString: id)!)

    @Test func aMessageOpensTheChat() {
        #expect(NotificationRoute(userInfo: ["request_id": Self.id, "opens": "chat"]) == .chat(Self.requestID))
    }

    @Test func everythingElseOpensTheRequest() {
        #expect(NotificationRoute(userInfo: ["request_id": Self.id, "opens": "request"]) == .request(Self.requestID))
        #expect(NotificationRoute(userInfo: ["request_id": Self.id]) == .request(Self.requestID))
    }

    @Test func aPayloadWithoutARequestOpensNothing() {
        #expect(NotificationRoute(userInfo: [:]) == nil)
        #expect(NotificationRoute(userInfo: ["request_id": "not-a-uuid"]) == nil)
        #expect(NotificationRoute(userInfo: ["request_id": 42]) == nil)
    }
}
