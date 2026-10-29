import FavorlyCore

/// Pushes a request's chat directly, for a tapped message notification.
struct ChatDestination: Hashable {
    let requestID: RequestID
}
