import FavorlyData
import FavorlyFeatures
import FavorlyRemote
import Supabase

extension AppEnvironment {
    /// The real backend for requests, chat, reviews, Kindness, the session and sign-in. Location is still the
    /// Dev Settings presets until phase 4D.
    @MainActor
    static func remote(_ configuration: RemoteConfiguration) -> AppEnvironment {
        let client = SupabaseClient(supabaseURL: configuration.url, supabaseKey: configuration.anonKey)
        let directory = RemoteProfileDirectory(client: client)
        let session = RemoteSessionStore(directory: directory)
        let repository = RemoteRepository(client: client, directory: directory)
        let locationSettings = MockLocationSettings()
        return AppEnvironment(
            repository: repository,
            kindness: repository,
            reviews: repository,
            chat: repository,
            locationProvider: MockLocationProvider(settings: locationSettings),
            session: session,
            auth: RemoteAuthService(client: client, session: session),
            locationSettings: locationSettings
        )
    }
}
