import Foundation
#if canImport(UIKit)
    import UIKit
#endif

enum SystemSettings {
    /// Favorly's page in the Settings app, where the user turns Location back on. Nil on macOS, where only the
    /// package tests run.
    @MainActor static var appURL: URL? {
        #if canImport(UIKit)
            URL(string: UIApplication.openSettingsURLString)
        #else
            nil
        #endif
    }
}
