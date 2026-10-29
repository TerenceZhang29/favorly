import FavorlyData
import FavorlyFeatures

extension AppEnvironment {
    /// The prototype's wiring: in-memory mocks seeded with demo data.
    @MainActor
    static func demo(artificialDelay: Duration = .milliseconds(300), startsSignedIn: Bool = true) -> AppEnvironment {
        let locationSettings = MockLocationSettings()
        // One actor serves every repository protocol, so rules that span requests and reviews stay atomic.
        let repository = MockRequestRepository(artificialDelay: artificialDelay)
        let session = MockSessionStore()
        return AppEnvironment(
            repository: repository,
            kindness: repository,
            reviews: repository,
            chat: repository,
            moderation: repository,
            locationProvider: MockLocationProvider(settings: locationSettings),
            session: session,
            auth: MockAuthService(session: session, startsSignedIn: startsSignedIn, artificialDelay: artificialDelay),
            push: MockPushRegistrar(),
            notifications: MockNotificationService(),
            locationSettings: locationSettings,
            router: AppDelegate.router
        )
    }
}
