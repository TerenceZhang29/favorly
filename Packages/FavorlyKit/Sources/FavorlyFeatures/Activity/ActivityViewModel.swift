import FavorlyCore
import Observation

@MainActor
@Observable
final class ActivityViewModel {
    enum State: Equatable {
        case loading
        case loaded(posted: [HelpRequest], pickedUp: [HelpRequest])
        case failed(String)
    }

    private(set) var state: State = .loading
    var segment = ActivitySegment.posted
    /// Reviews of the completed requests in either segment, by request, for the row actions and points.
    private(set) var reviewsByRequest: [RequestID: Review] = [:]
    /// The message of the last row action that failed, such as Mark completed.
    private(set) var actionError: String?

    @ObservationIgnored private let environment: AppEnvironment
    @ObservationIgnored private var latestLoad = 0

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    /// Changes when the user is switched, which should trigger a fresh load.
    var reloadKey: UserID {
        environment.session.currentUser.id
    }

    /// The requests in the selected segment, or nil until they have loaded.
    var items: [HelpRequest]? {
        guard case let .loaded(posted, pickedUp) = state else { return nil }
        return segment == .posted ? posted : pickedUp
    }

    /// The line under a request's title: its status, and who posted it when that is someone else.
    func subtitle(for request: HelpRequest) -> String {
        let status = environment.session.statusText(for: request)
        guard request.requesterID != environment.session.currentUser.id else { return status }
        return "\(status) · Posted by \(environment.session.displayName(for: request.requesterID))"
    }

    /// Loads both segments for the current user. Lists already on screen stay visible while they reload.
    func load() async {
        latestLoad += 1
        let load = latestLoad
        let user = environment.session.currentUser.id
        if case .failed = state {
            state = .loading
        }

        do {
            let posted = try await environment.repository.requests(postedBy: user)
            let pickedUp = try await environment.repository.requests(claimedBy: user)
            let reviews = await reviews(of: posted + pickedUp)
            guard load == latestLoad else { return }
            reviewsByRequest = reviews
            state = .loaded(posted: posted, pickedUp: pickedUp)
        } catch is CancellationError {
            // A newer load replaced this one.
        } catch {
            guard load == latestLoad else { return }
            state = .failed(ErrorMessage.text(for: error))
        }
    }

    // MARK: Row actions, as in the mockup

    /// Message the other person: while the request is claimed and the user is part of it.
    func canMessage(_ request: HelpRequest) -> Bool {
        request.status == .claimed && (try? ChatRules.validateSend(request: request, by: currentUserID)) != nil
    }

    /// Mark completed: only the requester, while it is claimed.
    func canComplete(_ request: HelpRequest) -> Bool {
        (try? RequestRules.validateComplete(request: request, by: currentUserID)) != nil
    }

    /// Leave a review: the requester, once it is completed and not yet reviewed.
    func canReview(_ request: HelpRequest) -> Bool {
        let existing = reviewsByRequest[request.id]
        return (try? ReviewRules.validateReviewer(request: request, by: currentUserID, existing: existing)) != nil
    }

    /// The Kindness points the user earned for helping with a completed request, such as "+18 pts", or nil
    /// for requests they didn't help with or that aren't completed.
    func earnedPointsText(for request: HelpRequest) -> String? {
        guard request.status == .completed, request.helperID == currentUserID else { return nil }
        let stars = reviewsByRequest[request.id]?.rating ?? 0
        return "+\(KindnessRules.pointsPerFavor + KindnessRules.pointsPerStar * stars) pts"
    }

    /// Marks one of the user's claimed requests completed, from its row.
    func complete(_ request: HelpRequest) async {
        actionError = nil
        do {
            _ = try await environment.repository.complete(request.id, by: currentUserID)
            await load()
        } catch {
            actionError = ErrorMessage.text(for: error)
        }
    }

    private var currentUserID: UserID {
        environment.session.currentUser.id
    }

    private func reviews(of requests: [HelpRequest]) async -> [RequestID: Review] {
        var reviews: [RequestID: Review] = [:]
        for request in requests where request.status == .completed {
            if let review = try? await environment.reviews.review(for: request.id) {
                reviews[request.id] = review
            }
        }
        return reviews
    }

    /// Reloads after every repository write. Runs until the surrounding task is cancelled.
    func observeChanges() async {
        for await _ in environment.repository.changes() {
            await load()
        }
    }
}
