import FavorlyCore
@testable import FavorlyDevice
import Foundation
import Testing

@MainActor
struct DeviceChatReadStoreTests {
    private let defaults: UserDefaults
    private let request = RequestID(rawValue: UUID())
    private let alex = UserID(rawValue: "alex")
    private let bea = UserID(rawValue: "bea")
    private let start = Date(timeIntervalSince1970: 1_000_000)

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "DeviceChatReadStoreTests.\(UUID().uuidString)"))
    }

    @Test func aPositionSurvivesANewStore() {
        DeviceChatReadStore(defaults: defaults).markRead(request, upTo: start, for: alex)
        #expect(DeviceChatReadStore(defaults: defaults).readUpTo(request, for: alex) == start)
    }

    @Test func eachAccountKeepsItsOwnPositionAndItNeverMovesBack() {
        let store = DeviceChatReadStore(defaults: defaults)
        store.markRead(request, upTo: start.addingTimeInterval(60), for: alex)
        store.markRead(request, upTo: start, for: alex)
        #expect(store.readUpTo(request, for: alex) == start.addingTimeInterval(60))
        #expect(store.readUpTo(request, for: bea) == nil)
        #expect(store.readUpTo(RequestID(rawValue: UUID()), for: alex) == nil)
    }
}
