import FavorlyCore
import Foundation

extension MockRequestRepository: ChatRepository {
    public func messages(for request: RequestID, as user: UserID) async throws -> [ChatMessage] {
        try await beginOperation()
        guard let helpRequest = requests[request] else { throw FavorlyError.notFound }
        try ChatRules.validateRead(request: helpRequest, by: user)
        return messages.filter { $0.requestID == request }
    }

    public func send(_ text: String, in request: RequestID, by user: UserID) async throws -> ChatMessage {
        try await beginOperation()
        guard let helpRequest = requests[request] else { throw FavorlyError.notFound }
        try ChatRules.validateSend(request: helpRequest, by: user)
        let text = try ChatRules.validateText(text)
        let message = ChatMessage(
            id: MessageID(rawValue: UUID()),
            requestID: request,
            senderID: user,
            text: text,
            sentAt: now()
        )
        messages.append(message)
        broadcaster.send()
        return message
    }
}
