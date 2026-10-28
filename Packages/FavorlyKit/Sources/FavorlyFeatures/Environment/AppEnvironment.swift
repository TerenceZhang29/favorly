import FavorlyCore

/// The services every screen works with. The App target decides which implementations go in.
public struct AppEnvironment: Sendable {
    public let repository: any RequestRepository
    public let kindness: any KindnessRepository
    public let reviews: any ReviewRepository
    public let chat: any ChatRepository
    public let moderation: any ModerationRepository
    public let locationProvider: any LocationProvider
    public let session: any SessionStore
    public let auth: any AuthService
    /// The Dev Settings location presets, for demo launches only; nil when the device's own location is used.
    public let locationSettings: (any LocationSettings)?

    public init(
        repository: any RequestRepository,
        kindness: any KindnessRepository,
        reviews: any ReviewRepository,
        chat: any ChatRepository,
        moderation: any ModerationRepository,
        locationProvider: any LocationProvider,
        session: any SessionStore,
        auth: any AuthService,
        locationSettings: (any LocationSettings)?
    ) {
        self.repository = repository
        self.kindness = kindness
        self.reviews = reviews
        self.chat = chat
        self.moderation = moderation
        self.locationProvider = locationProvider
        self.session = session
        self.auth = auth
        self.locationSettings = locationSettings
    }

    /// Who is signed in and where they are, such as "Alex @ Cornell Tech, Roosevelt Island".
    @MainActor public var debugSummary: String {
        let place = locationSettings?.selectedPreset.location.label ?? "this device's location"
        return "\(session.currentUser.displayName) @ \(place)"
    }
}
