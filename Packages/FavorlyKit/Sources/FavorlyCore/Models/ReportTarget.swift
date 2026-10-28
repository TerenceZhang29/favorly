import Foundation

/// What a report is about.
public enum ReportTarget: Hashable, Sendable {
    case request(RequestID)
    case message(MessageID)
    case user(UserID)
}
