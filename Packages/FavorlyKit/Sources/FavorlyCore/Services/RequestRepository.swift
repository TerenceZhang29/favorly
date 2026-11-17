import Foundation

public protocol RequestRepository: Sendable {
    func nearby(around point: GeoPoint, radiusMeters: Double) async throws -> [NearbyRequest]
    func request(id: RequestID) async throws -> HelpRequest
    func requests(postedBy user: UserID) async throws -> [HelpRequest]
    func requests(claimedBy user: UserID) async throws -> [HelpRequest]
    func create(_ draft: NewRequestDraft, by user: UserID) async throws -> HelpRequest
    func claim(_ id: RequestID, by user: UserID) async throws -> HelpRequest
    func cancel(_ id: RequestID, by user: UserID) async throws -> HelpRequest
    func complete(_ id: RequestID, by user: UserID) async throws -> HelpRequest
    /// Records that `user` opened the request, for usage metrics; counted once per person and request.
    /// The requester's own views, cancelled requests and requests between blocked people are skipped
    /// without an error. Nobody can read the views back through the app.
    func recordView(of id: RequestID, by user: UserID) async throws
    /// Emits after any write, so open screens refresh.
    func changes() -> AsyncStream<Void>
    /// Restores the seed data (dev settings).
    func reset() async
}
