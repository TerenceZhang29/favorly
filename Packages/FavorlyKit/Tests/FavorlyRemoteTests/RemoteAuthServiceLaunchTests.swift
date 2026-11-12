import FavorlyCore
@testable import FavorlyRemote
import Foundation
import Supabase
import Testing

/// The state at launch, before `restore()` finishes. None of these reach a backend.
@MainActor
struct RemoteAuthServiceLaunchTests {
    @Test func aSavedSessionStartsRestoringNotSignedOut() {
        #expect(RemoteAuthService.launchState(hasSavedSession: true) == .restoring)
    }

    @Test func noSavedSessionStartsSignedOut() {
        #expect(RemoteAuthService.launchState(hasSavedSession: false) == .signedOut)
    }

    @Test func aFreshInstallShowsWelcomeAtOnce() throws {
        let client = try SupabaseClient(
            supabaseURL: #require(URL(string: "http://127.0.0.1:1")),
            supabaseKey: "test-key",
            options: SupabaseClientOptions(auth: .init(storage: InMemoryAuthStorage()))
        )
        let session = RemoteSessionStore(directory: RemoteProfileDirectory(client: client))
        #expect(RemoteAuthService(client: client, session: session).state == .signedOut)
    }
}
