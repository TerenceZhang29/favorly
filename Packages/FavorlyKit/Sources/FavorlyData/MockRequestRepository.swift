import FavorlyCore
import Foundation

/// The one in-memory store behind every repository protocol. Its conformances to the Phase 3 protocols live in
/// `MockRequestRepository+<Feature>.swift`, so the state they share is internal rather than private.
public actor MockRequestRepository: RequestRepository {
    private let seed: @Sendable () -> [HelpRequest]
    private let reviewSeed: @Sendable () -> [Review]
    private let artificialDelay: Duration
    let now: @Sendable () -> Date
    let broadcaster = ChangeBroadcaster()
    var requests: [RequestID: HelpRequest]
    var reviews: [Review]
    /// Oldest first, across all users.
    var redemptions: [Redemption] = []
    /// Oldest first, across all threads. The seed has none.
    var messages: [ChatMessage] = []
    /// Oldest first.
    var reports: [MockReport] = []
    /// Who each person blocked, newest first.
    var blocks: [UserID: [UserID]] = [:]

    /// - Parameters:
    ///   - seed: Builds the starting requests, and again on every `reset()`.
    ///   - reviewSeed: Builds the starting reviews, and again on every `reset()`.
    ///   - artificialDelay: Wait before each read or write, so loading states are visible.
    ///   - now: The clock used for `createdAt`, `claimedAt`, the time of a redemption or a message, and for
    ///     deciding when a picked-up request completes on its own.
    public init(
        seed: @escaping @Sendable () -> [HelpRequest] = { DemoRequests.all() },
        reviewSeed: @escaping @Sendable () -> [Review] = { DemoReviews.all() },
        artificialDelay: Duration = .milliseconds(300),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.seed = seed
        self.reviewSeed = reviewSeed
        self.artificialDelay = artificialDelay
        self.now = now
        requests = Self.indexed(seed())
        reviews = reviewSeed()
    }

    // MARK: Reads

    public func nearby(around point: GeoPoint, radiusMeters: Double) async throws -> [NearbyRequest] {
        try await beginOperation()
        return requests.values
            .filter { $0.status == .open }
            .map { NearbyRequest(request: $0, distanceMeters: Distance.meters(from: point, to: $0.location.point)) }
            .filter { $0.distanceMeters <= radiusMeters }
            .sorted {
                if $0.distanceMeters != $1.distanceMeters {
                    return $0.distanceMeters < $1.distanceMeters
                }
                return $0.request.createdAt > $1.request.createdAt
            }
    }

    public func request(id: RequestID) async throws -> HelpRequest {
        try await beginOperation()
        guard let request = requests[id] else { throw FavorlyError.notFound }
        return request
    }

    public func requests(postedBy user: UserID) async throws -> [HelpRequest] {
        try await beginOperation()
        return requests.values
            .filter { $0.requesterID == user }
            .sorted { $0.createdAt > $1.createdAt }
    }

    public func requests(claimedBy user: UserID) async throws -> [HelpRequest] {
        try await beginOperation()
        return requests.values
            .filter { $0.helperID == user }
            .sorted { ($0.claimedAt ?? $0.createdAt) > ($1.claimedAt ?? $1.createdAt) }
    }

    // MARK: Writes

    public func create(_ draft: NewRequestDraft, by user: UserID) async throws -> HelpRequest {
        try await beginOperation()
        let draft = try DraftValidator.validate(draft)
        let request = HelpRequest(
            id: RequestID(rawValue: UUID()),
            title: draft.title,
            details: draft.details,
            category: draft.category,
            location: draft.location,
            requesterID: user,
            createdAt: now()
        )
        requests[request.id] = request
        broadcaster.send()
        return request
    }

    public func claim(_ id: RequestID, by user: UserID) async throws -> HelpRequest {
        let claimedAt = now()
        return try await update(id) { request in
            try RequestRules.validateClaim(request: request, by: user)
            guard !isBlockedBetween(user, request.requesterID) else { throw FavorlyError.blocked }
            request.helperID = user
            request.claimedAt = claimedAt
            request.status = .claimed
        }
    }

    public func cancel(_ id: RequestID, by user: UserID) async throws -> HelpRequest {
        try await update(id) { request in
            try RequestRules.validateCancel(request: request, by: user)
            request.status = .cancelled
        }
    }

    public func complete(_ id: RequestID, by user: UserID) async throws -> HelpRequest {
        try await update(id) { request in
            try RequestRules.validateComplete(request: request, by: user)
            request.status = .completed
        }
    }

    public nonisolated func changes() -> AsyncStream<Void> {
        broadcaster.stream()
    }

    /// Restores requests and reviews to the seed and removes every redemption, message, report and block.
    public func reset() async {
        requests = Self.indexed(seed())
        reviews = reviewSeed()
        redemptions = []
        messages = []
        reports = []
        blocks = [:]
        broadcaster.send()
    }

    // MARK: Helpers

    /// Validates and mutates one request in a single actor turn, so two claims cannot both succeed.
    private func update(_ id: RequestID, _ change: (inout HelpRequest) throws -> Void) async throws -> HelpRequest {
        try await beginOperation()
        guard var request = requests[id] else { throw FavorlyError.notFound }
        try change(&request)
        requests[id] = request
        broadcaster.send()
        return request
    }

    /// Runs before every read and write: waits out the artificial delay, then completes each picked-up request
    /// that is due (rule 15). There is no timer, so a fixed `now` in tests decides what is due.
    func beginOperation() async throws {
        if artificialDelay > .zero {
            try await Task.sleep(for: artificialDelay)
        }
        completeDueRequests()
    }

    private func completeDueRequests() {
        let date = now()
        let due = requests.values.filter { RequestRules.isAutoCompleteDue($0, now: date) }
        guard !due.isEmpty else { return }
        for var request in due {
            request.status = .completed
            requests[request.id] = request
        }
        broadcaster.send()
    }

    private static func indexed(_ requests: [HelpRequest]) -> [RequestID: HelpRequest] {
        Dictionary(requests.map { ($0.id, $0) }) { _, latest in latest }
    }
}
