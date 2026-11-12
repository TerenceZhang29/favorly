import FavorlyCore
import Foundation
import Testing

@MainActor
struct ChatUnreadTests {
    private let request = RequestID(rawValue: UUID())
    private let start = Date(timeIntervalSince1970: 1_000_000)

    private func message(from sender: UserID, at minutes: Double) -> ChatMessage {
        ChatMessage(
            id: MessageID(rawValue: UUID()),
            requestID: request,
            senderID: sender,
            text: "Hi",
            sentAt: start.addingTimeInterval(minutes * 60)
        )
    }

    @Test func neverOpenedCountsEveryMessageFromTheOtherPerson() {
        let thread = [message(from: .helper, at: 1), message(from: .requester, at: 2), message(from: .helper, at: 3)]
        #expect(ChatRules.unreadCount(in: thread, for: .requester, readUpTo: nil) == 2)
        #expect(ChatRules.unreadCount(in: thread, for: .helper, readUpTo: nil) == 1)
    }

    @Test func onlyMessagesAfterTheReadPositionCount() {
        let thread = [message(from: .helper, at: 1), message(from: .helper, at: 2), message(from: .helper, at: 3)]
        #expect(ChatRules.unreadCount(in: thread, for: .requester, readUpTo: start.addingTimeInterval(120)) == 1)
        #expect(ChatRules.unreadCount(in: thread, for: .requester, readUpTo: start.addingTimeInterval(180)) == 0)
    }

    @Test func theInMemoryStoreKeepsEachUsersPositionAndNeverMovesBack() {
        let store = InMemoryChatReadStore()
        #expect(store.readUpTo(request, for: .requester) == nil)
        store.markRead(request, upTo: start.addingTimeInterval(60), for: .requester)
        store.markRead(request, upTo: start, for: .requester)
        #expect(store.readUpTo(request, for: .requester) == start.addingTimeInterval(60))
        #expect(store.readUpTo(request, for: .helper) == nil)
    }
}
