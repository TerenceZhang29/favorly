import Foundation

/// Read positions kept for the life of the process: demo launches, tests and previews.
@MainActor
public final class InMemoryChatReadStore: ChatReadStore {
    private var positions: [String: Date] = [:]

    public init() {}

    public func readUpTo(_ request: RequestID, for user: UserID) -> Date? {
        positions[Self.key(request, user)]
    }

    public func markRead(_ request: RequestID, upTo date: Date, for user: UserID) {
        let key = Self.key(request, user)
        if let saved = positions[key], saved >= date {
            return
        }
        positions[key] = date
    }

    private static func key(_ request: RequestID, _ user: UserID) -> String {
        "\(user.rawValue)|\(request.rawValue.uuidString)"
    }
}
