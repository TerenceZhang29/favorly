import FavorlyCore
import Foundation

/// Read positions saved in `UserDefaults`, so unread counts survive relaunches. Keyed by user and request, so two
/// accounts on one phone keep their own.
@MainActor
public final class DeviceChatReadStore: ChatReadStore {
    static let key = "favorly.chatReadPositions"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func readUpTo(_ request: RequestID, for user: UserID) -> Date? {
        positions[Self.entry(request, user)].map(Date.init(timeIntervalSince1970:))
    }

    public func markRead(_ request: RequestID, upTo date: Date, for user: UserID) {
        var positions = positions
        let entry = Self.entry(request, user)
        if let saved = positions[entry], saved >= date.timeIntervalSince1970 {
            return
        }
        positions[entry] = date.timeIntervalSince1970
        defaults.set(positions, forKey: Self.key)
    }

    private var positions: [String: Double] {
        defaults.dictionary(forKey: Self.key) as? [String: Double] ?? [:]
    }

    private static func entry(_ request: RequestID, _ user: UserID) -> String {
        "\(user.rawValue)|\(request.rawValue.uuidString)"
    }
}
