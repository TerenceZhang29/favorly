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
    /// `-demoReplies` makes the other person in a thread answer the user's messages, for the App Store screenshots.
    /// Debug demo launches only.
    private static let repliesInDemo: Bool = {
        #if DEBUG
            isDemo && arguments.contains("-demoReplies")
        #else
            false
        #endif
    }()

    /// `-hideStatusBar` hides the time, signal and battery, for the App Store screenshots. Debug builds only.
    private static let hidesStatusBar: Bool = {
        #if DEBUG
            arguments.contains("-hideStatusBar")
        #else
            false
        #endif
    }()

    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var environment = makeEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appEnvironment, environment)
                .statusBarHidden(Self.hidesStatusBar)
                .task {
                    appDelegate.environment = environment
                    await signInAtLaunch()
                }
                .task {
                    #if DEBUG
                        if Self.repliesInDemo {
                            await DemoReplier(environment: environment).run()
                        }
                    #endif
                }
                .task(id: environment.auth.state) {
                    // A signed-in user's device token can change; registering again keeps the server's copy fresh.
                    if environment.auth.state == .signedIn {
                        await environment.notifications.registerIfAllowed()
                    }
                }
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
