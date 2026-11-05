import Foundation

enum ActivitySegment: String, CaseIterable, Identifiable, Sendable {
    case posted
    case pickedUp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .posted: "My requests"
        case .pickedUp: "Claimed by me"
        }
    }

    var emptyMessage: String {
        switch self {
        case .posted: "You haven't posted any requests yet."
        case .pickedUp: "You haven't claimed any requests yet."
        }
    }
}
