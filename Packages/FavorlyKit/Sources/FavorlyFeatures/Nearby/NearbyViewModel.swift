import FavorlyCore
import Observation

@MainActor
@Observable
final class NearbyViewModel {
    enum State: Equatable {
        case loading
        case loaded([NearbyRequest])
        case empty
        case failed(String)
        /// Location is off for Favorly; the screen offers Settings instead of Retry.
        case locationDenied(String)
    }

    /// Everything that should trigger a fresh load when it changes.
    struct ReloadKey: Hashable {
        /// Nil on the device's own location.
        let preset: LocationPreset?
        let simulatesError: Bool
        let radius: RadiusOption
    }

    private(set) var state: State = .loading
    var radius = RadiusOption.default
    /// Where the last list was loaded around.
    private(set) var location: TaggedLocation?

    @ObservationIgnored private let environment: AppEnvironment
    @ObservationIgnored private var latestLoad = 0

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    var reloadKey: ReloadKey {
        ReloadKey(
            preset: environment.locationSettings?.selectedPreset,
            simulatesError: environment.locationSettings?.simulatesError ?? false,
            radius: radius
        )
    }

    /// "Near Roosevelt Island", the neighborhood the list is around; "Location is off" when it is denied; nil
    /// before the first location.
    var locationText: String? {
        if case .locationDenied = state {
            return "Location is off"
        }
        return location.map { "Near \($0.label)" }
    }

    /// "7 requests", or nil when there is no list to count.
    var countText: String? {
        guard case let .loaded(results) = state else { return nil }
        return results.count == 1 ? "1 request" : "\(results.count) requests"
    }

    var emptyMessage: String {
        "No requests within \(radius.title)"
    }

    func isOwn(_ request: HelpRequest) -> Bool {
        request.requesterID == environment.session.currentUser.id
    }

    func requesterName(for request: HelpRequest) -> String {
        environment.session.displayName(for: request.requesterID)
    }

    /// Loads requests around the current location. An existing list stays visible while it reloads.
    func load() async {
        latestLoad += 1
        let load = latestLoad
        switch state {
        case .failed, .locationDenied:
            state = .loading
        default:
            break
        }

        do {
            let location = try await environment.locationProvider.currentLocation()
            let found = try await environment.repository.nearby(around: location.point, radiusMeters: radius.meters)
            // The server already hides them; the mock cannot, since its reads do not know who is asking.
            let blocked = await blockedUserIDs()
            let results = found.filter { !blocked.contains($0.request.requesterID) }
            guard load == latestLoad else { return }
            self.location = location
            state = results.isEmpty ? .empty : .loaded(results)
        } catch is CancellationError {
            // A newer load replaced this one.
        } catch {
            guard load == latestLoad else { return }
            state = error as? FavorlyError == .locationPermissionDenied
                ? .locationDenied(ErrorMessage.text(for: error))
                : .failed(ErrorMessage.text(for: error))
        }
    }

    /// People the signed-in user blocked. A failed lookup hides no one.
    private func blockedUserIDs() async -> Set<UserID> {
        let blocked = try? await environment.moderation.blockedUsers(of: environment.session.currentUser.id)
        return Set((blocked ?? []).map(\.id))
    }

    /// Reloads after every repository write. Runs until the surrounding task is cancelled.
    func observeChanges() async {
        for await _ in environment.repository.changes() {
            await load()
        }
    }
}
