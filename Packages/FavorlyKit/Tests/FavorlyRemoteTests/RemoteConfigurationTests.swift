import FavorlyCore
@testable import FavorlyRemote
import Foundation
import Testing

struct RemoteConfigurationTests {
    @Test func readsTheURLAndKeyFromInfo() throws {
        let configuration = try #require(RemoteConfiguration(info: [
            "FavorlySupabaseURL": "https://example.supabase.co",
            "FavorlySupabaseAnonKey": "public-anon-key",
        ]))
        #expect(configuration.url.absoluteString == "https://example.supabase.co")
        #expect(configuration.anonKey == "public-anon-key")
    }

    @Test(arguments: [
        [String: String](),
        ["FavorlySupabaseURL": "https://example.supabase.co"],
        ["FavorlySupabaseURL": "https://example.supabase.co", "FavorlySupabaseAnonKey": ""],
        ["FavorlySupabaseURL": "", "FavorlySupabaseAnonKey": "key"],
    ])
    func missingValuesMeanNoBackend(info: [String: String]) {
        #expect(RemoteConfiguration(info: info) == nil)
    }

    @Test func serverUserIDsAreLowercasedUUIDs() throws {
        let id = try #require(UUID(uuidString: "9F77130F-1396-4761-B317-9B422B16C155"))
        let user = UserID(remote: id)
        #expect(user.rawValue == "9f77130f-1396-4761-b317-9b422b16c155")
        #expect(user.remoteID == id)
        #expect(UserID(rawValue: "user-alex").remoteID == nil)
    }
}
