import Foundation

/// Why something is reported. Raw values match the server's `report_reason`.
public enum ReportReason: String, CaseIterable, Codable, Sendable {
    case spam, inappropriate, unsafe, other
}
