import FavorlyFeatures
import FavorlyRemote
import Foundation

extension AppEnvironment {
    /// What a normal launch uses: the Supabase project in `Config/Backend.xcconfig` (or `Local.xcconfig`).
    /// Without one, the demo wiring starting at Welcome, so a build with no backend still runs.
    @MainActor
    static func live() -> AppEnvironment {
        guard let configuration = RemoteConfiguration(info: Bundle.main.infoDictionary ?? [:]) else {
            return demo(startsSignedIn: false)
        }
        return remote(configuration)
    }
}
