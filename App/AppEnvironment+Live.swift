import FavorlyFeatures

extension AppEnvironment {
    /// What a normal launch uses. Until phase 4C wires the backend, it is the demo wiring starting at Welcome.
    @MainActor
    static func live() -> AppEnvironment {
        demo(startsSignedIn: false)
    }
}
