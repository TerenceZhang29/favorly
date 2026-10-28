import FavorlyCore
import Foundation

struct MessageRow: Decodable, Sendable {
    let id: UUID
    let requestID: UUID
    let senderID: UUID
    let text: String
    let sentAt: Date

    enum CodingKeys: String, CodingKey {
        case id, text
        case requestID = "request_id"
        case senderID = "sender_id"
        case sentAt = "sent_at"
    }

    func model() -> ChatMessage {
        ChatMessage(
            id: MessageID(rawValue: id),
            requestID: RequestID(rawValue: requestID),
            senderID: UserID(remote: senderID),
            text: text,
            sentAt: sentAt
        )
    }
}
