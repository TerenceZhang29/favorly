import FavorlyCore
import Foundation

/// Where tapping a notification goes, read from its payload (`request_id` and `opens`, set by the server).
public enum NotificationRoute: Hashable, Sendable {
    case request(RequestID)
    case chat(RequestID)

    public init?(userInfo: [AnyHashable: Any]) {
        guard let text = userInfo["request_id"] as? String, let uuid = UUID(uuidString: text) else { return nil }
        let id = RequestID(rawValue: uuid)
        self = userInfo["opens"] as? String == "chat" ? .chat(id) : .request(id)
    }
}
