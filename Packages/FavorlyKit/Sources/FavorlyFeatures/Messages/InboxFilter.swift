/// The segments at the top of the Messages tab.
enum InboxFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    /// Threads on requests the user posted.
    case mine
    /// Threads on requests the user is helping with.
    case helping

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .mine: "My requests"
        case .helping: "Helping"
        }
    }

    var emptyMessage: String {
        switch self {
        case .all: "No conversations yet. A chat starts when someone claims your request, or you claim theirs."
        case .mine: "No one has claimed your requests yet."
        case .helping: "You aren't helping with any requests yet."
        }
    }

    func includes(_ thread: InboxThread) -> Bool {
        switch self {
        case .all: true
        case .mine: thread.isMyRequest
        case .helping: !thread.isMyRequest
        }
    }
}
