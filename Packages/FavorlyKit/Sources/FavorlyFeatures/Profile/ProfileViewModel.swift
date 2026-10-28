import FavorlyCore
import Foundation
import Observation

/// One user's profile: who they are, their Kindness score, and their completed favors.
/// On the Profile tab the owner can also sign out or delete their account.
@MainActor
@Observable
final class ProfileViewModel {
    struct Content: Equatable {
        let user: UserProfile
        let summary: KindnessSummary
        /// Completed requests the user helped with or asked for, newest first.
        let activities: [ProfileActivity]
        /// Newest first.
        let reviews: [Review]
    }

    enum State: Equatable {
        case loading
        case loaded(Content)
        case failed(String)
    }

    private(set) var state: State = .loading
    /// Why the last sign out or account deletion failed.
    private(set) var accountError: String?
    private(set) var isDeletingAccount = false

    /// The user whose profile this is, or nil for the signed-in user (the Profile tab).
    private let subjectID: UserID?
    @ObservationIgnored private let environment: AppEnvironment
    @ObservationIgnored private var latestLoad = 0

    init(userID: UserID? = nil, environment: AppEnvironment) {
        subjectID = userID
        self.environment = environment
    }

    /// Changes when the user is switched, which should trigger a fresh load.
    var reloadKey: UserID {
        environment.session.currentUser.id
    }

    var userID: UserID {
        subjectID ?? environment.session.currentUser.id
    }

    /// The Profile tab, where the signed-in user manages their account.
    var showsAccount: Bool {
        subjectID == nil
    }

    /// Someone else's profile: they can be reported or blocked.
    var canReportOrBlock: Bool {
        guard let subjectID else { return false }
        return subjectID != environment.session.currentUser.id
    }

    var content: Content? {
        guard case let .loaded(content) = state else { return nil }
        return content
    }

    // MARK: Display text

    /// "5 favors completed", "1 favor completed" or "No favors yet".
    var favorsText: String {
        guard let count = content?.summary.completedFavors, count > 0 else { return "No favors yet" }
        return count == 1 ? "1 favor completed" : "\(count) favors completed"
    }

    /// "4.5 average from 2 reviews", "5.0 average from 1 review" or "No reviews yet".
    var ratingText: String {
        guard let summary = content?.summary, let average = summary.averageRating else { return "No reviews yet" }
        let reviews = summary.reviewCount == 1 ? "1 review" : "\(summary.reviewCount) reviews"
        return "\(Self.ratingFormat(average)) average from \(reviews)"
    }

    func displayName(for id: UserID) -> String {
        environment.session.displayName(for: id)
    }

    // MARK: Loading

    /// Loads the profile. A profile already on screen stays visible while it reloads.
    func load() async {
        latestLoad += 1
        let load = latestLoad
        let user = userID
        if case .failed = state {
            state = .loading
        }

        do {
            let summary = try await environment.kindness.kindnessSummary(for: user)
            let posted = try await environment.repository.requests(postedBy: user)
            let pickedUp = try await environment.repository.requests(claimedBy: user)
            let reviews = try await environment.reviews.reviews(about: user)
            guard load == latestLoad else { return }
            state = .loaded(Content(
                user: profile(for: user),
                summary: summary,
                activities: Self.activities(posted: posted, pickedUp: pickedUp),
                reviews: reviews
            ))
        } catch is CancellationError {
            // A newer load replaced this one.
        } catch {
            guard load == latestLoad else { return }
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

    /// Blocks this profile's person. Returns true when done, so the screen can close.
    func block() async -> Bool {
        guard canReportOrBlock else { return false }
        accountError = nil
        do {
            try await environment.moderation.block(userID, by: environment.session.currentUser.id)
            return true
        } catch is CancellationError {
            return false
        } catch {
            accountError = ErrorMessage.text(for: error)
            return false
        }
    }

    /// Back to the Welcome screen.
    func signOut() async {
        accountError = nil
        await environment.auth.signOut()
    }

    /// Deletes the account for good, then returns to the Welcome screen. The view confirms first.
    func deleteAccount() async {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true
        defer { isDeletingAccount = false }
        accountError = nil

        do {
            try await environment.auth.deleteAccount()
        } catch is CancellationError {
            // The screen went away.
        } catch {
            accountError = ErrorMessage.text(for: error)
        }
    }

    // MARK: Helpers

    private func profile(for id: UserID) -> UserProfile {
        environment.session.profile(for: id)
            ?? UserProfile(id: id, displayName: environment.session.displayName(for: id), neighborhood: "")
    }

    /// Completed requests only, on every profile: open and cancelled ones stay private to their owner.
    private static func activities(posted: [HelpRequest], pickedUp: [HelpRequest]) -> [ProfileActivity] {
        let asked = posted.filter { $0.status == .completed }.map { ProfileActivity(request: $0, role: .asked) }
        let helped = pickedUp.filter { $0.status == .completed }.map { ProfileActivity(request: $0, role: .helped) }
        return (asked + helped).sorted { date(of: $0.request) > date(of: $1.request) }
    }

    /// When the favor happened, as near as the model knows: the pick-up time.
    private static func date(of request: HelpRequest) -> Date {
        request.claimedAt ?? request.createdAt
    }

    private static func ratingFormat(_ average: Double) -> String {
        String(format: "%.1f", average)
    }
}
