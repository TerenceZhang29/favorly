import FavorlyCore
import Foundation
import Supabase

extension RemoteRepository: ChatRepository {
    /// Row-level security returns nothing to anyone but the requester and helper; the mock throws `notAllowed`.
    public func messages(for request: RequestID, as _: UserID) async throws -> [ChatMessage] {
        let rows: [MessageRow] = try await call {
            try await client.from("messages")
                .select()
                .eq("request_id", value: request.rawValue)
                .order("sent_at", ascending: true)
                .execute()
                .value
        }
        return rows.map { $0.model() }
    }

    /// One query for every thread; row-level security leaves out the ones the user isn't in.
    public func messages(inRequests ids: [RequestID], as _: UserID) async throws -> [ChatMessage] {
        guard !ids.isEmpty else { return [] }
        let rows: [MessageRow] = try await call {
            try await client.from("messages")
                .select()
                .in("request_id", values: ids.map(\.rawValue.uuidString))
                .order("sent_at", ascending: true)
                .execute()
                .value
        }
        return rows.map { $0.model() }
    }

    public func send(_ text: String, in request: RequestID, by _: UserID) async throws -> ChatMessage {
        let text = try ChatRules.validateText(text)
        let params: [String: AnyJSON] = ["request_id": .string(request.rawValue.uuidString), "text": .string(text)]
        let row: MessageRow = try await call {
            try await client.rpc("send_message", params: params)
                .execute()
                .value
        }
        broadcaster.send()
        return row.model()
    }
}
