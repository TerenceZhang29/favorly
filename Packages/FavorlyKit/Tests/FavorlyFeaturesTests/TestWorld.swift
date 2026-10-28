import FavorlyCore
import FavorlyData
@testable import FavorlyFeatures
import Foundation

/// The mock services behind one test, kept so the test can reach past the protocols.
@MainActor
struct TestWorld {
    nonisolated static let now = Date(timeIntervalSince1970: 1_000_000)
    static let eggsID = seedID(1)
    static let riceID = seedID(2)
    static let ladderID = seedID(6)

    let repository = MockRequestRepository(
        seed: { DemoRequests.all(now: now) },
        reviewSeed: { DemoReviews.all(now: now) },
        artificialDelay: .zero,
        now: { now }
    )
    let session: MockSessionStore
    let auth: MockAuthService
    let locationSettings = MockLocationSettings()

    init(startsSignedIn: Bool = true) {
        let session = MockSessionStore()
        self.session = session
        auth = MockAuthService(session: session, startsSignedIn: startsSignedIn, artificialDelay: .zero)
    }

    var environment: AppEnvironment {
        AppEnvironment(
            repository: repository,
            kindness: repository,
            reviews: repository,
            chat: repository,
            locationProvider: MockLocationProvider(settings: locationSettings),
            session: session,
            auth: auth,
            locationSettings: locationSettings
        )
    }

    /// Like a normal launch: the given location provider and no Dev Settings presets.
    func deviceEnvironment(locationProvider: any LocationProvider) -> AppEnvironment {
        AppEnvironment(
            repository: repository,
            kindness: repository,
            reviews: repository,
            chat: repository,
            locationProvider: locationProvider,
            session: session,
            auth: auth,
            locationSettings: nil
        )
    }

    static func seedID(_ number: UInt8) -> RequestID {
        RequestID(rawValue: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, number)))
    }

    /// Waits up to two seconds for `condition`, for work that finishes on another task.
    static func eventually(_ condition: () -> Bool) async -> Bool {
        for _ in 0 ..< 200 {
            if condition() {
                return true
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return condition()
    }
}
