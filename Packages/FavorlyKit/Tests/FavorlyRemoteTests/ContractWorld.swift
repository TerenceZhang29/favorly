import FavorlyCore
import FavorlyData
import FavorlyRemote
import Foundation
import Supabase

/// Signs up people on one backend, at a spot of their own, so tests never see each other's requests.
@MainActor
final class ContractWorld {
    let backend: ContractBackend
    /// A random place, so requests left on the local backend by earlier runs are never nearby.
    let here: TaggedLocation
    private let mock = MockRequestRepository(seed: { [] }, reviewSeed: { [] }, artificialDelay: .zero)

    init(_ backend: ContractBackend) {
        self.backend = backend
        here = TaggedLocation(
            point: GeoPoint(latitude: .random(in: 20 ... 60), longitude: .random(in: -150 ... -70)),
            label: "Test block"
        )
    }

    /// A place about `meters` north of `here`.
    func north(by meters: Double) -> TaggedLocation {
        TaggedLocation(
            point: GeoPoint(latitude: here.point.latitude + meters / 111_000, longitude: here.point.longitude),
            label: "Further up"
        )
    }

    func draft(_ title: String, at location: TaggedLocation? = nil) -> NewRequestDraft {
        NewRequestDraft(title: title, details: "", category: .ingredient, location: location ?? here)
    }

    func signUp(_ name: String) async throws -> ContractUser {
        switch backend {
        case .mock:
            let id = UserID(rawValue: "user-\(name.lowercased())-\(UUID().uuidString.prefix(8))")
            return ContractUser(id: id, requests: mock, chat: mock, reviews: mock, kindness: mock)
        case .remote:
            let environment = ProcessInfo.processInfo.environment
            guard let url = environment["FAVORLY_SUPABASE_URL"].flatMap(URL.init(string:)),
                  let key = environment["FAVORLY_SUPABASE_ANON_KEY"]
            else { throw ContractSetupError.missingConfiguration }
            let client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: key,
                options: SupabaseClientOptions(auth: .init(storage: InMemoryAuthStorage()))
            )
            let directory = RemoteProfileDirectory(client: client)
            let session = RemoteSessionStore(directory: directory)
            let auth = RemoteAuthService(client: client, session: session)
            let email = "\(name.lowercased())-\(UUID().uuidString.lowercased())@test.local"
            try await auth.signIn(email: email, password: "contract-test-password", createAccount: true)
            try await auth.completeProfile(ProfileSetupDraft(
                displayName: name,
                confirmedAdult: true,
                acceptedTerms: true
            ))
            let repository = RemoteRepository(client: client, directory: directory)
            return ContractUser(
                id: session.currentUser.id,
                requests: repository,
                chat: repository,
                reviews: repository,
                kindness: repository
            )
        }
    }
}

enum ContractSetupError: Error {
    case missingConfiguration
}
