import FavorlyFeatures
import SwiftUI

@main
struct FavorlyApp: App {
    private static let arguments = ProcessInfo.processInfo.arguments
    /// UI tests pass `-uiTesting` to drop the mock network delay. Data is in memory, so every launch starts fresh.
    private static let isUITesting = arguments.contains("-uiTesting")
    /// `-demo` (set in the Run scheme) and `-uiTesting` start signed in as Alex with demo data.
    private static let isDemo = isUITesting || arguments.contains("-demo")
    /// `-signedOut` starts a demo launch at the Welcome screen, for the onboarding UI tests.
    private static let startsSignedOut = arguments.contains("-signedOut")

    @State private var environment = isDemo
        ? AppEnvironment.demo(
            artificialDelay: isUITesting ? .zero : .milliseconds(300),
            startsSignedIn: !startsSignedOut
        )
        : AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appEnvironment, environment)
        }
    }
}
