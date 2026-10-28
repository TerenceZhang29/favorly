import FavorlyCore

/// A report as the mock stored it, so tests can see what was sent.
public struct MockReport: Equatable, Sendable {
    public let target: ReportTarget
    public let reason: ReportReason
    public let note: String
    public let reporterID: UserID

    public init(target: ReportTarget, reason: ReportReason, note: String, reporterID: UserID) {
        self.target = target
        self.reason = reason
        self.note = note
        self.reporterID = reporterID
    }
}
