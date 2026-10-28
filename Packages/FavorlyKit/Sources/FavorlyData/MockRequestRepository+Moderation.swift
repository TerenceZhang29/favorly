import FavorlyCore
import Foundation

/// Reports and blocks in memory. Like the server, a block stops pick-ups and messages between the two people;
/// unlike it, the mock's reads cannot hide them, since its reads do not know who is asking. Screens filter
/// out people the user blocked themselves.
extension MockRequestRepository: ModerationRepository {
    public func report(_ target: ReportTarget, reason: ReportReason, note: String, by user: UserID) async throws {
        try await beginOperation()
        switch target {
        case let .request(id):
            guard requests[id] != nil else { throw FavorlyError.notFound }
        case let .message(id):
            guard messages.contains(where: { $0.id == id }) else { throw FavorlyError.notFound }
        case let .user(id):
            try ReportRules.validateNotSelf(id, by: user)
        }
        let note = try ReportRules.validateNote(note)
        reports.append(MockReport(target: target, reason: reason, note: note, reporterID: user))
    }

    public func block(_ blocked: UserID, by user: UserID) async throws {
        try await beginOperation()
        try ReportRules.validateNotSelf(blocked, by: user)
        guard !(blocks[user] ?? []).contains(blocked) else { return }
        blocks[user, default: []].insert(blocked, at: 0)
        broadcaster.send()
    }

    public func unblock(_ blocked: UserID, by user: UserID) async throws {
        try await beginOperation()
        blocks[user]?.removeAll { $0 == blocked }
        broadcaster.send()
    }

    public func blockedUsers(of user: UserID) async throws -> [UserProfile] {
        try await beginOperation()
        return (blocks[user] ?? []).map { id in
            DemoUsers.all.first { $0.id == id } ?? UserProfile(id: id, displayName: "A neighbor", neighborhood: "")
        }
    }

    /// Every report sent so far, oldest first.
    public func submittedReports() -> [MockReport] {
        reports
    }

    /// True when either person blocked the other.
    func isBlockedBetween(_ first: UserID, _ second: UserID?) -> Bool {
        guard let second else { return false }
        return (blocks[first] ?? []).contains(second) || (blocks[second] ?? []).contains(first)
    }
}
