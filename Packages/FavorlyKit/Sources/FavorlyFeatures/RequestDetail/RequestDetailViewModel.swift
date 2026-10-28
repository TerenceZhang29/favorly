import FavorlyCore
import Foundation
import Observation

@MainActor
@Observable
final class RequestDetailViewModel {
    enum State: Equatable {
        case loading
        case loaded(HelpRequest)
        case failed(String)
    }

    let requestID: RequestID
    private(set) var state: State = .loading
    /// Rounded distance from the current location, or nil when the location is unavailable.
    private(set) var distanceText: String?
    /// Why the last pick up, cancel or complete failed.
    private(set) var actionError: String?
    private(set) var isWorking = false
    /// Kindness scores of the requester and the helper, or nil until known. A failed lookup leaves them out.
    private(set) var requesterScore: Int?
    private(set) var helperScore: Int?
    /// The requester's review of the helper, once there is one.
    private(set) var review: Review?

    @ObservationIgnored private let environment: AppEnvironment

    init(requestID: RequestID, environment: AppEnvironment) {
        self.requestID = requestID
        self.environment = environment
    }

    var request: HelpRequest? {
        guard case let .loaded(request) = state else { return nil }
        return request
    }

    // MARK: What the current user sees

    var isOwn: Bool {
        request?.requesterID == currentUserID
    }

    var requesterName: String {
        guard let request else { return "" }
        return environment.session.displayName(for: request.requesterID)
    }

    var helperName: String? {
        request?.helperID.map { environment.session.displayName(for: $0) }
    }

    /// "Open", "Claimed by Bea", "Completed" or "Cancelled".
    var statusText: String {
        request.map { environment.session.statusText(for: $0) } ?? ""
    }

    var canPickUp: Bool {
        allows(RequestRules.validateClaim)
    }

    var canCancel: Bool {
        allows(RequestRules.validateCancel)
    }

    /// The requester only (rule 15).
    var canComplete: Bool {
        allows(RequestRules.validateComplete)
    }

    /// For the helper of a picked-up request, when it completes on its own (rule 15); nil for everyone else.
    var autoCompleteDate: Date? {
        guard let request, request.helperID == currentUserID else { return nil }
        return RequestRules.autoCompleteDate(of: request)
    }

    /// "Completes automatically on Oct 20 if Alex doesn't confirm." Shown to the helper instead of Mark completed.
    var autoCompleteNote: String? {
        autoCompleteDate.map {
            "Completes automatically on \($0.formatted(.dateTime.month(.abbreviated).day())) if \(requesterName) doesn't confirm."
        }
    }

    /// The requester, on a completed request they have not reviewed yet.
    var canReview: Bool {
        guard let request else { return false }
        return ReviewRules.canReview(request: request, by: currentUserID, existing: review)
    }

    /// "Your review" for the person who wrote it, "Review" for everyone else.
    var reviewTitle: String {
        review?.reviewerID == currentUserID ? "Your review" : "Review"
    }

    /// The request is picked up and the signed-in user is its requester or helper.
    var canMessage: Bool {
        allows(ChatRules.validateRead)
    }

    /// "Message Bea": names the other person in the thread.
    var messageButtonTitle: String {
        guard let request else { return "" }
        let otherID = request.requesterID == currentUserID ? request.helperID : request.requesterID
        return "Message \(otherID.map { environment.session.displayName(for: $0) } ?? "")"
    }

    // MARK: Loading

    /// Loads the request. A request already on screen stays visible while it reloads.
    func load() async {
        do {
            let request = try await environment.repository.request(id: requestID)
            let location = try? await environment.locationProvider.currentLocation()
            distanceText = location.map {
                DistanceFormatter.miles(Distance.meters(from: $0.point, to: request.location.point))
            }
            await loadExtras(of: request)
            state = .loaded(request)
        } catch is CancellationError {
            // The screen went away.
        } catch {
            state = .failed(ErrorMessage.text(for: error))
        }
    }

    /// Reloads after every repository write. Runs until the surrounding task is cancelled.
    func observeChanges() async {
        for await _ in environment.repository.changes() {
            await load()
        }
    }

    // MARK: Actions

    func pickUp() async {
        await perform(environment.repository.claim)
    }

    func cancel() async {
        await perform(environment.repository.cancel)
    }

    func complete() async {
        await perform(environment.repository.complete)
    }

    // MARK: Helpers

    /// Loads the scores beside the names and the review. A failed lookup leaves them out.
    private func loadExtras(of request: HelpRequest) async {
        review = if request.status == .completed {
            try? await environment.reviews.review(for: request.id)
        } else {
            nil
        }
        requesterScore = await score(of: request.requesterID)
        helperScore = if let helperID = request.helperID {
            await score(of: helperID)
        } else {
            nil
        }
    }

    private func score(of user: UserID) async -> Int? {
        try? await environment.kindness.kindnessSummary(for: user).lifetimePoints
    }

    private var currentUserID: UserID {
        environment.session.currentUser.id
    }

    private func allows(_ rule: (HelpRequest, UserID) throws -> Void) -> Bool {
        guard let request else { return false }
        return (try? rule(request, currentUserID)) != nil
    }

    private func perform(_ action: (RequestID, UserID) async throws -> HelpRequest) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        actionError = nil

        do {
            let request = try await action(requestID, currentUserID)
            await loadExtras(of: request)
            state = .loaded(request)
        } catch is CancellationError {
            // The screen went away.
        } catch {
            actionError = ErrorMessage.text(for: error)
            // Show what changed underneath, such as someone else's claim.
            await load()
        }
    }
}
