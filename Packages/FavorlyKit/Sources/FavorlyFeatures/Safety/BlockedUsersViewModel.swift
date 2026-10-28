import FavorlyCore
import Observation

/// The people the signed-in user blocked, with Unblock.
@MainActor
@Observable
final class BlockedUsersViewModel {
    enum State: Equatable {
        case loading
        case loaded([UserProfile])
        case failed(String)
    }

    private(set) var state: State = .loading
    /// Why the last unblock failed.
    private(set) var actionError: String?

    @ObservationIgnored private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func load() async {
        do {
            state = try await .loaded(environment.moderation.blockedUsers(of: environment.session.currentUser.id))
        } catch is CancellationError {
            // The screen went away.
        } catch {
            state = .failed(ErrorMessage.text(for: error))
        }
    }

    func unblock(_ user: UserProfile) async {
        actionError = nil
        do {
            try await environment.moderation.unblock(user.id, by: environment.session.currentUser.id)
            await load()
        } catch is CancellationError {
            // The screen went away.
        } catch {
            actionError = ErrorMessage.text(for: error)
        }
    }
}
