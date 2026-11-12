import SwiftUI

/// Restoring a saved session: the logo and a progress bar. Signed out: Welcome.
/// Signed in but new: profile setup. Otherwise the tabs.
public struct RootView: View {
    @Environment(\.appEnvironment) private var environment

    public init() {
        #if canImport(UIKit)
            GroveAppearance.applyIfNeeded()
        #endif
    }

    public var body: some View {
        Group {
            switch environment.auth.state {
            case .restoring:
                LaunchLoadingView()
            case .signedOut:
                WelcomeView(environment: environment)
            case .needsProfile:
                NavigationStack {
                    ProfileSetupView(environment: environment)
                }
            case .signedIn:
                MainTabView(environment: environment)
            }
        }
        .tint(Theme.Colors.brand)
        .font(TextStyle.body.font)
    }
}

#Preview {
    RootView()
}
