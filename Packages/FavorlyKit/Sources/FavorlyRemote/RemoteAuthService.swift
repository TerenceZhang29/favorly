import FavorlyCore
import Foundation
import Observation
import Supabase

/// Sign-in against Supabase auth. The app signs in with Apple; email sign-in exists for development and tests
/// against a local backend, and is turned off on the hosted project.
@MainActor
@Observable
public final class RemoteAuthService: AuthService {
    public private(set) var state: AuthState
    public let usesAppleSignIn = true

    @ObservationIgnored private let client: SupabaseClient
    @ObservationIgnored private let session: RemoteSessionStore
    @ObservationIgnored private let retryDelay: Duration

    /// - Parameter retryDelay: The first wait before loading the profile again when it can't be reached; it doubles
    ///   on each try, up to 30 seconds.
    public init(client: SupabaseClient, session: RemoteSessionStore, retryDelay: Duration = .seconds(2)) {
        self.client = client
        self.session = session
        self.retryDelay = retryDelay
        // Reading the saved session is local and synchronous, so a signed-out user sees Welcome at once, and a
        // signed-in user never sees it flash by while `restore()` loads their profile.
        state = Self.launchState(hasSavedSession: client.auth.currentSession != nil)
    }

    /// The state before `restore()` finishes: restoring when an earlier launch saved a session.
    static func launchState(hasSavedSession: Bool) -> AuthState {
        hasSavedSession ? .restoring : .signedOut
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

    /// Signed in: the profile decides between profile setup and the tabs. When the profile can't be loaded, the user
    /// saved on this device opens the tabs; with none saved, the state stays `.restoring` and loading is tried again,
    /// since an existing user must never be sent to profile setup. A session the server refuses signs out.
    private func loadOwnProfile() async {
        var delay = retryDelay
        while true {
            guard let id = client.auth.currentUser?.id else {
                state = .signedOut
                return
            }
            do {
                let rows: [ProfileRow] = try await client.from("profiles")
                    .select("id, display_name, neighborhood")
                    .eq("id", value: id)
                    .limit(1)
                    // This loop retries; the SDK's own retries would hold an offline launch for seconds.
                    .retry(enabled: false)
                    .execute()
                    .value
                if let row = rows.first {
                    session.signIn(as: row.model())
                    state = .signedIn
                } else {
                    state = .needsProfile
                }
                return
            } catch {
                switch RemoteErrors.favorlyError(from: error) {
                case is CancellationError:
                    return
                case FavorlyError.notSignedIn:
                    await signOut()
                    return
                default:
                    break
                }
            }
            if let saved = session.savedUser(for: UserID(remote: id)) {
                session.signIn(as: saved)
                state = .signedIn
                return
            }
            state = .restoring
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            delay = min(delay * 2, .seconds(30))
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
