import FavorlyDevice
import FavorlyFeatures
import FavorlyRemote
import Supabase

extension AppEnvironment {
    /// The real backend for requests, chat, reviews, Kindness, the session and sign-in, and the device's own
    /// location, so there are no Dev Settings presets.
    @MainActor
    static func remote(_ configuration: RemoteConfiguration) -> AppEnvironment {
        let client = SupabaseClient(supabaseURL: configuration.url, supabaseKey: configuration.anonKey)
        let directory = RemoteProfileDirectory(client: client)
        let session = RemoteSessionStore(directory: directory)
        let repository = RemoteRepository(client: client, directory: directory)
        return AppEnvironment(
            repository: repository,
            kindness: repository,
            reviews: repository,
            chat: repository,
            moderation: repository,
            locationProvider: DeviceLocationProvider(source: CoreLocationSource(), namer: GeocoderNeighborhoodNamer()),
            session: session,
            auth: RemoteAuthService(client: client, session: session),
            push: RemotePushRegistrar(client: client),
            notifications: SystemNotificationService(),
            locationSettings: nil
        )
    }
}
