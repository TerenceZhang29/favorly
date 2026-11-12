import FavorlyCore

/// Previews show empty threads; sending throws.
extension PreviewRequestRepository: ChatRepository {
    func messages(for request: RequestID, as user: UserID) async throws -> [ChatMessage] {
        let helpRequest = try await self.request(id: request)
        try ChatRules.validateRead(request: helpRequest, by: user)
        return []
    }

    func messages(inRequests _: [RequestID], as _: UserID) async throws -> [ChatMessage] {
        []
    }

    func send(_: String, in _: RequestID, by _: UserID) async throws -> ChatMessage {
        throw FavorlyError.notAllowed
    }
}
