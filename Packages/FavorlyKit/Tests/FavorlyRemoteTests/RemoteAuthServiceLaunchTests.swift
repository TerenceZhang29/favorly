import FavorlyCore
@testable import FavorlyRemote
import Foundation
import Supabase
import Testing

/// The state at launch, before and after `restore()`. The backend address refuses connections, so a saved session
/// behaves as a launch without a connection; none of these reach a real backend.
@MainActor
struct RemoteAuthServiceLaunchTests {
    private static let userID = UUID()
    private let storage = InMemoryAuthStorage()
    private let defaults: UserDefaults
    private let client: SupabaseClient
    private let session: RemoteSessionStore

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "RemoteAuthServiceLaunchTests.\(UUID().uuidString)"))
        client = try SupabaseClient(
            supabaseURL: #require(URL(string: "http://127.0.0.1:1")),
            supabaseKey: "test-key",
            options: SupabaseClientOptions(auth: .init(storage: storage, storageKey: "test-auth"))
        )
        session = RemoteSessionStore(directory: RemoteProfileDirectory(client: client), defaults: defaults)
    }

    @Test func aSavedSessionStartsRestoringNotSignedOut() {
        #expect(RemoteAuthService.launchState(hasSavedSession: true) == .restoring)
    }

    @Test func noSavedSessionStartsSignedOut() {
        #expect(RemoteAuthService.launchState(hasSavedSession: false) == .signedOut)
    }

    @Test func aFreshInstallShowsWelcomeAtOnce() {
        #expect(RemoteAuthService(client: client, session: session).state == .signedOut)
    }

    @Test func offlineWithASavedUserOpensTheTabs() async throws {
        try saveSession()
        let alex = UserProfile(id: UserID(remote: Self.userID), displayName: "Alex", neighborhood: "Chelsea")
        session.signIn(as: alex)
        let auth = RemoteAuthService(client: client, session: session, retryDelay: .seconds(60))
        #expect(auth.state == .restoring)

        await auth.restore()

        #expect(auth.state == .signedIn)
        #expect(session.currentUser == alex)
    }

    @Test func offlineWithNoSavedUserKeepsRestoringInsteadOfProfileSetup() async throws {
        try saveSession()
        let auth = RemoteAuthService(client: client, session: session, retryDelay: .milliseconds(20))

        let restoring = Task { await auth.restore() }
        try await Task.sleep(for: .milliseconds(300))
        #expect(auth.state == .restoring)

        restoring.cancel()
        await restoring.value
        #expect(auth.state == .restoring)
    }

    @Test func theSavedUserBelongsToOneAccountAndSignOutClearsIt() {
        let alex = UserProfile(id: UserID(remote: Self.userID), displayName: "Alex", neighborhood: "Chelsea")
        session.signIn(as: alex)
        #expect(session.savedUser(for: alex.id) == alex)
        #expect(session.savedUser(for: UserID(remote: UUID())) == nil)

        session.signOut()
        #expect(session.savedUser(for: alex.id) == nil)
    }

    /// Stores a session that has not expired, as an earlier launch would have.
    private func saveSession() throws {
        let now = Date()
        let user = User(id: Self.userID, appMetadata: [:], userMetadata: [:], aud: "authenticated", createdAt: now,
                        updatedAt: now)
        let saved = Session(accessToken: "test-access", tokenType: "bearer", expiresIn: 3600,
                            expiresAt: now.addingTimeInterval(3600).timeIntervalSince1970,
                            refreshToken: "test-refresh", user: user)
        try storage.store(key: "test-auth", value: JSONEncoder().encode(saved))
        #expect(client.auth.currentSession != nil)
    }
}
