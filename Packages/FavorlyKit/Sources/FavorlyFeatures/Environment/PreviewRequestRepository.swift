import FavorlyCore

/// A read-only repository over fixed requests and reviews. Every write throws `notAllowed`.
struct PreviewRequestRepository: RequestRepository {
    let requests: [HelpRequest]
    var reviews: [Review] = []

    func nearby(around point: GeoPoint, radiusMeters: Double) async throws -> [NearbyRequest] {
        requests
            .filter { $0.status == .open }
            .map { NearbyRequest(request: $0, distanceMeters: Distance.meters(from: point, to: $0.location.point)) }
            .filter { $0.distanceMeters <= radiusMeters }
            .sorted { $0.distanceMeters < $1.distanceMeters }
    }

    func request(id: RequestID) async throws -> HelpRequest {
        guard let request = requests.first(where: { $0.id == id }) else { throw FavorlyError.notFound }
        return request
    }

    func requests(postedBy user: UserID) async throws -> [HelpRequest] {
        requests.filter { $0.requesterID == user }
    }

    func requests(claimedBy user: UserID) async throws -> [HelpRequest] {
        requests.filter { $0.helperID == user }
    }

    func create(_: NewRequestDraft, by _: UserID) async throws -> HelpRequest {
        throw FavorlyError.notAllowed
    }

    func claim(_: RequestID, by _: UserID) async throws -> HelpRequest {
        throw FavorlyError.notAllowed
    }

    func cancel(_: RequestID, by _: UserID) async throws -> HelpRequest {
        throw FavorlyError.notAllowed
    }

    func complete(_: RequestID, by _: UserID) async throws -> HelpRequest {
        throw FavorlyError.notAllowed
    }

    func recordView(of _: RequestID, by _: UserID) async throws {}

    func changes() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }

    func reset() async {}
}
