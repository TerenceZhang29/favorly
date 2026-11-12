import FavorlyCore
import Foundation

/// One conversation in the Messages tab: a request with a helper, the other person in it and its latest message.
struct InboxThread: Identifiable, Hashable, Sendable {
    let requestID: RequestID
    let otherName: String
    let favorTitle: String
    /// The signed-in user posted the request; otherwise they are helping with it.
    let isMyRequest: Bool
    let status: RequestStatus
    let lastMessage: ChatMessage?
    let lastIsMine: Bool
    let unreadCount: Int
    /// The latest message's time, or when the request was claimed; the inbox is sorted by it, newest first.
    let activityDate: Date

    var id: RequestID { requestID }

    /// "Your request", "You're helping", "Completed" or "Cancelled", above the last message.
    var roleText: String {
        switch status {
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        case .open, .claimed: isMyRequest ? "Your request" : "You're helping"
        }
    }

    /// The last message, with "You: " before the user's own; a prompt while the thread is empty.
    var previewText: String {
        guard let lastMessage else { return "No messages yet. Say hello." }
        return lastIsMine ? "You: \(lastMessage.text)" : lastMessage.text
    }

    /// "2 unread", for the badge's VoiceOver label; nil when everything is read.
    var unreadLabel: String? {
        unreadCount > 0 ? "\(unreadCount) unread" : nil
    }

    /// The time for today's messages, otherwise the day, such as "Nov 1".
    func timeText(now: Date, calendar: Calendar = .current) -> String {
        calendar.isDate(activityDate, inSameDayAs: now)
            ? activityDate.formatted(date: .omitted, time: .shortened)
            : activityDate.formatted(.dateTime.month(.abbreviated).day())
    }
}
