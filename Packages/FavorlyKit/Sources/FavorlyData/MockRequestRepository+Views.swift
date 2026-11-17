import FavorlyCore
import Foundation

/// Request views, with the server's rules (`record_request_view`): once per person and request, never the
/// requester's own, and nothing for a cancelled or unknown request or between blocked people.
public extension MockRequestRepository {
    func recordView(of id: RequestID, by user: UserID) async throws {
        try await beginOperation()
        guard let request = requests[id],
              request.requesterID != user,
              request.status != .cancelled,
              !isBlockedBetween(user, request.requesterID)
        else { return }
        viewers[id, default: []].insert(user)
    }

    /// How many people opened the request, for tests. The app has no way to read views.
    func viewerCount(of id: RequestID) -> Int {
        viewers[id]?.count ?? 0
    }
}
