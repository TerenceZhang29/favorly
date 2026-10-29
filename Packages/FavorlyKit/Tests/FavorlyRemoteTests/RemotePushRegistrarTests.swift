import FavorlyCore
@testable import FavorlyRemote
import Foundation
import Supabase
import Testing

struct RemotePushRegistrarTests {
    @Test func tokensAreLowercaseHex() {
        #expect(RemotePushRegistrar.hex(Data([0x00, 0xAB, 0x0F, 0xFF])) == "00ab0fff")
    }

    @Test func debugBuildsRegisterSandboxTokens() {
        // Tests always build in Debug.
        #expect(RemotePushRegistrar.environment == "sandbox")
    }

    /// Registers and unregisters a device on the local backend; runs with the contract tests' variables.
    @MainActor
    @Test(.enabled(if: ContractBackend.enabled.contains(.remote)))
    func aDeviceRegistersOnTheLocalBackend() async throws {
        let environment = ProcessInfo.processInfo.environment
        let url = try #require(environment["FAVORLY_SUPABASE_URL"].flatMap(URL.init(string:)))
        let key = try #require(environment["FAVORLY_SUPABASE_ANON_KEY"])
        let client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: SupabaseClientOptions(auth: .init(storage: InMemoryAuthStorage()))
        )
        let session = RemoteSessionStore(directory: RemoteProfileDirectory(client: client))
        let auth = RemoteAuthService(client: client, session: session)
        let email = "push-\(UUID().uuidString.lowercased())@test.local"
        try await auth.signIn(email: email, password: "contract-test-password", createAccount: true)
        try await auth.completeProfile(ProfileSetupDraft(displayName: "Pat", confirmedAdult: true, acceptedTerms: true))

        let registrar = RemotePushRegistrar(client: client)
        try await registrar.register(deviceToken: Data((0 ..< 32).map { UInt8($0) }))
        await registrar.unregister()
    }
}
