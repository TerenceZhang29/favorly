import FavorlyCore

/// A message that just arrived from the other person in a thread, shown in the banner at the top of the app.
struct IncomingMessage: Identifiable, Hashable, Sendable {
    let messageID: MessageID
    let requestID: RequestID
    let senderName: String
    let favorTitle: String
    let text: String

    var id: MessageID { messageID }

    /// What VoiceOver says when the banner appears.
    var announcement: String {
        "New message from \(senderName): \(text)"
    }
}
