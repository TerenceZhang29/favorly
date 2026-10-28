import FavorlyCore
import Foundation
import Supabase

extension RemoteRepository: ModerationRepository {
    public func report(_ target: ReportTarget, reason: ReportReason, note: String, by _: UserID) async throws {
        let note = try ReportRules.validateNote(note)
        let (type, id): (String, String) = switch target {
        case let .request(id): ("request", id.rawValue.uuidString)
        case let .message(id): ("message", id.rawValue.uuidString)
        case let .user(id): ("user", id.rawValue)
        }
        let params: [String: AnyJSON] = [
            "target_type": .string(type),
            "target_id": .string(id),
            "reason": .string(reason.rawValue),
            "note": .string(note),
        ]
        try await call { try await client.rpc("report", params: params).execute() }
    }

    public func block(_ blocked: UserID, by _: UserID) async throws {
        try await call { try await client.rpc("block_user", params: ["user_id": AnyJSON.string(blocked.rawValue)]).execute() }
        broadcaster.send()
    }

    public func unblock(_ blocked: UserID, by _: UserID) async throws {
        try await call {
            try await client.rpc("unblock_user", params: ["user_id": AnyJSON.string(blocked.rawValue)]).execute()
        }
        broadcaster.send()
    }

    public func blockedUsers(of _: UserID) async throws -> [UserProfile] {
        let rows: [ProfileRow] = try await call { try await client.rpc("blocked_profiles").execute().value }
        return rows.map { $0.model() }
    }
}
