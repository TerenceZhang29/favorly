import SwiftUI

/// Signed out: Welcome. Signed in but new: profile setup. Otherwise the tabs.
public struct RootView: View {
    @Environment(\.appEnvironment) private var environment

    public init() {}

    public var body: some View {
        switch environment.auth.state {
        case .signedOut:
            WelcomeView(environment: environment)
        case .needsProfile:
            NavigationStack {
                ProfileSetupView(environment: environment)
            }
        case .signedIn:
            MainTabView()
        }
    }
}

#Preview {
    RootView()
}
