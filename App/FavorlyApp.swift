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

    private static func makeEnvironment() -> AppEnvironment {
        if let configuration = remoteConfiguration {
            return .remote(configuration)
        }
        return isDemo
            ? .demo(artificialDelay: isUITesting ? .zero : .milliseconds(300), startsSignedIn: !startsSignedOut)
            : .live()
    }

    /// `-remote` uses the Supabase project in `Config/Local.xcconfig`. Debug builds only, until Sign in with
    /// Apple works (phase 4C); after that a normal launch will use it.
    private static var remoteConfiguration: RemoteConfiguration? {
        #if DEBUG
            guard arguments.contains("-remote") else { return nil }
            return RemoteConfiguration(info: Bundle.main.infoDictionary ?? [:])
        #else
            return nil
        #endif
    }

    /// Restores a saved session; in Debug, `-devEmail` and `-devPassword` sign in by email (creating the account
    /// the first time), since Sign in with Apple needs the paid developer account.
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
