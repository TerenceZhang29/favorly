import FavorlyCore
import Foundation
import Observation
import Supabase

/// Sign-in against Supabase auth. The app signs in with Apple; email sign-in exists for development and tests
/// against a local backend, and is turned off on the hosted project.
@MainActor
@Observable
public final class RemoteAuthService: AuthService {
    public private(set) var state = AuthState.signedOut
    public let usesAppleSignIn = true

    @ObservationIgnored private let client: SupabaseClient
    @ObservationIgnored private let session: RemoteSessionStore

    public init(client: SupabaseClient, session: RemoteSessionStore) {
        self.client = client
        self.session = session
    }

    /// Picks up a session saved by an earlier launch.
    public func restore() async {
        guard client.auth.currentSession != nil else {
            state = .signedOut
            return
        }
        await loadOwnProfile()
    }

    public func signInWithApple(identityToken: String, nonce: String) async throws {
        try await perform {
            _ = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(provider: .apple, idToken: identityToken, nonce: nonce)
            )
        }
        await loadOwnProfile()
    }

    /// Signs in with email and password, creating the account first when `createAccount` is true.
    public func signIn(email: String, password: String, createAccount: Bool = false) async throws {
        try await perform {
            if createAccount {
                _ = try await client.auth.signUp(email: email, password: password)
            } else {
                _ = try await client.auth.signIn(email: email, password: password)
            }
        }
        await loadOwnProfile()
    }

    public func completeProfile(_ draft: ProfileSetupDraft) async throws {
        guard state == .needsProfile else { throw FavorlyError.notAllowed }
        let draft = try ProfileSetupRules.validate(draft)
        let params: [String: AnyJSON] = [
            "display_name": .string(draft.displayName),
            "confirmed_adult": .bool(draft.confirmedAdult),
            "accepted_terms_version": .integer(draft.acceptedTerms ? ProfileSetupRules.termsVersion : 0),
        ]
        let row: ProfileRow = try await perform {
            try await client.rpc("complete_profile", params: params).execute().value
        }
        session.signIn(as: row.model())
        state = .signedIn
    }

    public func signOut() async {
        try? await client.auth.signOut(scope: .local)
        session.signOut()
        state = .signedOut
    }

    public func deleteAccount() async throws {
        guard state == .signedIn else { throw FavorlyError.notAllowed }
        try await perform { try await client.rpc("delete_my_account").execute() }
        await signOut()
    }

    // MARK: Helpers

    /// Signed in: the profile decides between profile setup and the tabs.
    private func loadOwnProfile() async {
        guard let id = client.auth.currentUser?.id else {
            state = .signedOut
            return
        }
        do {
            let rows: [ProfileRow] = try await client.from("profiles")
                .select("id, display_name, neighborhood")
                .eq("id", value: id)
                .limit(1)
                .execute()
                .value
            if let row = rows.first {
                session.signIn(as: row.model())
                state = .signedIn
            } else {
                state = .needsProfile
            }
        } catch {
            // Offline at launch: keep the session, and ask again on the next action.
            state = .needsProfile
        }
    }

    @discardableResult
    private func perform<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch {
            throw RemoteErrors.favorlyError(from: error)
        }
    }
}
