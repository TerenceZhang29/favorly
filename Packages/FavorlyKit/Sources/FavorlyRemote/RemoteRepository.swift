import FavorlyCore
import Foundation
import Supabase

/// Every repository protocol against the Supabase backend, like `MockRequestRepository` against memory.
/// Its conformances to the Phase 3 protocols live in `RemoteRepository+<Feature>.swift`.
///
/// The `user` parameters of the write methods are not sent: the server acts as whoever holds the session,
/// which is the signed-in user the app passes anyway.
public actor RemoteRepository: RequestRepository {
    let client: SupabaseClient
    let directory: RemoteProfileDirectory
    let broadcaster = RemoteChangeBroadcaster()
    private var realtime: Task<Void, Never>?

    public init(client: SupabaseClient, directory: RemoteProfileDirectory) {
        self.client = client
        self.directory = directory
    }

    // MARK: Reads

    public func nearby(around point: GeoPoint, radiusMeters: Double) async throws -> [NearbyRequest] {
        let params: [String: AnyJSON] = [
            "center_latitude": .double(point.latitude),
            "center_longitude": .double(point.longitude),
            "radius_m": .double(radiusMeters),
        ]
        let rows: [NearbyRow] = try await call {
            try await client.rpc("nearby_requests", params: params).execute().value
        }
        let requests = try rows.map { try $0.model() }
        await loadPeople(in: requests.map(\.request))
        return requests
    }

    public func request(id: RequestID) async throws -> HelpRequest {
        let rows: [RequestRow] = try await call {
            try await client.from("requests").select().eq("id", value: id.rawValue).limit(1).execute().value
        }
        guard let request = try rows.first?.model() else { throw FavorlyError.notFound }
        await loadPeople(in: [request])
        return request
    }

    public func requests(postedBy user: UserID) async throws -> [HelpRequest] {
        guard let id = user.remoteID else { return [] }
        return try await requests { $0.eq("requester_id", value: id).order("created_at", ascending: false) }
    }

    public func requests(claimedBy user: UserID) async throws -> [HelpRequest] {
        guard let id = user.remoteID else { return [] }
        return try await requests { $0.eq("helper_id", value: id).order("claimed_at", ascending: false) }
    }

    // MARK: Writes

    public func create(_ draft: NewRequestDraft, by _: UserID) async throws -> HelpRequest {
        // The same checks as the server, so the message matches the mock's without a round trip.
        let draft = try DraftValidator.validate(draft)
        let params: [String: AnyJSON] = [
            "title": .string(draft.title),
            "details": .string(draft.details),
            "category": .string(draft.category.rawValue),
            "latitude": .double(draft.location.point.latitude),
            "longitude": .double(draft.location.point.longitude),
            "location_label": .string(draft.location.label),
        ]
        return try await write { try await client.rpc("create_request", params: params).execute().value }
    }

    public func claim(_ id: RequestID, by _: UserID) async throws -> HelpRequest {
        try await move(id, by: "claim_request", to: .claimed)
    }

    public func cancel(_ id: RequestID, by _: UserID) async throws -> HelpRequest {
        try await move(id, by: "cancel_request", to: .cancelled)
    }

    public func complete(_ id: RequestID, by _: UserID) async throws -> HelpRequest {
        try await move(id, by: "complete_request", to: .completed)
    }

    /// Emits after this app's writes at once, and after anyone's through realtime.
    public nonisolated func changes() -> AsyncStream<Void> {
        let stream = broadcaster.stream()
        Task { await startRealtimeIfNeeded() }
        return stream
    }

    /// Demo data only lives in the mock; there is nothing to reset on a server.
    public func reset() async {}

    // MARK: Helpers

    /// Runs a call and turns its errors into `FavorlyError`.
    @discardableResult
    func call<T>(transitionTo: RequestStatus = .completed, _ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch {
            throw RemoteErrors.favorlyError(from: error, transitionTo: transitionTo)
        }
    }

    /// A write that returns a request row: maps errors, announces the change, and loads the names.
    private func write(
        transitionTo: RequestStatus = .completed,
        _ work: () async throws -> RequestRow
    ) async throws -> HelpRequest {
        let request = try await call(transitionTo: transitionTo, work).model()
        broadcaster.send()
        await loadPeople(in: [request])
        return request
    }

    /// Calls `function` (claim, cancel or complete) for one request.
    private func move(_ id: RequestID, by function: String, to status: RequestStatus) async throws -> HelpRequest {
        let params: [String: AnyJSON] = ["request_id": .string(id.rawValue.uuidString)]
        return try await write(transitionTo: status) {
            try await client.rpc(function, params: params).execute().value
        }
    }

    private func requests(
        _ filter: (PostgrestFilterBuilder) -> PostgrestTransformBuilder
    ) async throws -> [HelpRequest] {
        let rows: [RequestRow] = try await call {
            try await filter(client.from("requests").select()).execute().value
        }
        let requests = try rows.map { try $0.model() }
        await loadPeople(in: requests)
        return requests
    }

    private func loadPeople(in requests: [HelpRequest]) async {
        await directory.load(Set(requests.flatMap { [$0.requesterID] + ($0.helperID.map { [$0] } ?? []) }))
    }

    private func startRealtimeIfNeeded() {
        guard realtime == nil else { return }
        let channel = client.channel("favorly-changes")
        let streams = ["requests", "messages", "reviews"].map {
            channel.postgresChange(AnyAction.self, schema: "public", table: $0)
        }
        let broadcaster = broadcaster
        realtime = Task {
            await withTaskGroup(of: Void.self) { group in
                for stream in streams {
                    group.addTask {
                        for await _ in stream {
                            broadcaster.send()
                        }
                    }
                }
                group.addTask {
                    // Without realtime, screens still refresh after this app's own writes.
                    try? await channel.subscribeWithError()
                }
            }
        }
    }
}
