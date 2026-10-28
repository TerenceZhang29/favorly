import FavorlyCore

/// Previews report and block nothing.
extension PreviewRequestRepository: ModerationRepository {
    func report(_: ReportTarget, reason _: ReportReason, note _: String, by _: UserID) async throws {}

    func block(_: UserID, by _: UserID) async throws {}

    func unblock(_: UserID, by _: UserID) async throws {}

    func blockedUsers(of _: UserID) async throws -> [UserProfile] {
        []
    }
}
