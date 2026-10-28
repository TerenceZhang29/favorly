import Foundation

/// Reporting and blocking (guideline 1.2). Moderators read reports outside the app.
public protocol ModerationRepository: Sendable {
    /// Throws `notFound` for something that does not exist, `notAllowed` for reporting yourself.
    func report(_ target: ReportTarget, reason: ReportReason, note: String, by user: UserID) async throws
    /// Hides the two people from each other. Blocking someone already blocked does nothing.
    func block(_ blocked: UserID, by user: UserID) async throws
    func unblock(_ blocked: UserID, by user: UserID) async throws
    /// The people `user` has blocked, by name.
    func blockedUsers(of user: UserID) async throws -> [UserProfile]
}
