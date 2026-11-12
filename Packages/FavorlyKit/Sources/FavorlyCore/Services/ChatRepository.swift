import Foundation

public protocol ChatRepository: Sendable {
    /// Oldest first.
    func messages(for request: RequestID, as user: UserID) async throws -> [ChatMessage]
    /// Every message in the threads of `requests` that `user` can read, oldest first, for the Messages inbox.
    /// Threads the user can't read are left out rather than failing the whole call.
    func messages(inRequests requests: [RequestID], as user: UserID) async throws -> [ChatMessage]
    func send(_ text: String, in request: RequestID, by user: UserID) async throws -> ChatMessage
}
