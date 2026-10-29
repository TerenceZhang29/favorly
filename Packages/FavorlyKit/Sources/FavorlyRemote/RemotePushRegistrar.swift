import FavorlyCore
import Foundation
import Supabase

/// Saves the device token on the server for the signed-in user (`register_device`).
public actor RemotePushRegistrar: PushRegistrar {
    private let client: SupabaseClient
    private var registeredToken: String?

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func register(deviceToken: Data) async throws {
        let token = Self.hex(deviceToken)
        let params: [String: AnyJSON] = ["token": .string(token), "environment": .string(Self.environment)]
        do {
            try await client.rpc("register_device", params: params).execute()
        } catch {
            throw RemoteErrors.favorlyError(from: error)
        }
        registeredToken = token
    }

    public func unregister() async {
        guard let token = registeredToken else { return }
        registeredToken = nil
        _ = try? await client.rpc("unregister_device", params: ["token": AnyJSON.string(token)]).execute()
    }

    /// APNs device tokens as the server stores them: lowercase hex.
    static func hex(_ token: Data) -> String {
        token.map { String(format: "%02x", $0) }.joined()
    }

    /// Debug builds get sandbox tokens; TestFlight and App Store builds, which are Release, production ones.
    static var environment: String {
        #if DEBUG
            "sandbox"
        #else
            "production"
        #endif
    }
}
