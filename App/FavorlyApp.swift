import FavorlyFeatures
import FavorlyRemote
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

    @State private var environment = makeEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appEnvironment, environment)
                .task { await signInAtLaunch() }
        }
    }

    /// Demo data for `-demo` and UI tests; otherwise the backend, as a downloaded app runs.
    private static func makeEnvironment() -> AppEnvironment {
        isDemo
            ? .demo(artificialDelay: isUITesting ? .zero : .milliseconds(300), startsSignedIn: !startsSignedOut)
            : .live()
    }

    /// Restores a saved session. In Debug, `-devEmail` and `-devPassword` sign in by email (creating the account
    /// the first time), for a second simulator or the local backend, where Sign in with Apple is not set up.
    private func signInAtLaunch() async {
        guard let auth = environment.auth as? RemoteAuthService else { return }
        await auth.restore()
        #if DEBUG
            let defaults = UserDefaults.standard
            guard auth.state == .signedOut,
                  let email = defaults.string(forKey: "devEmail"),
                  let password = defaults.string(forKey: "devPassword")
            else { return }
            if await (try? auth.signIn(email: email, password: password)) == nil {
                try? await auth.signIn(email: email, password: password, createAccount: true)
            }
        #endif
    }
}
