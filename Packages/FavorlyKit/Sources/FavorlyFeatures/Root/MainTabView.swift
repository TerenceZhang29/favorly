import FavorlyCore
import SwiftUI

/// The app's tabs, for a signed-in user.
struct MainTabView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var selection: RootTab = .nearby
    /// The request just posted, highlighted in My Activity until the user leaves that tab.
    @State private var newlyPostedID: RequestID?

    var body: some View {
        TabView(selection: $selection) {
            ForEach(RootTab.visible) { tab in
                NavigationStack {
                    content(for: tab)
                        .appDestinations(environment)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .tag(tab)
                .accessibilityIdentifier("root.tab.\(tab.rawValue)")
            }
        }
        .tint(Theme.Colors.brand)
        .onChange(of: selection) { previous, _ in
            if previous == .activity {
                newlyPostedID = nil
            }
        }
    }

    @ViewBuilder
    private func content(for tab: RootTab) -> some View {
        switch tab {
        case .nearby:
            NearbyView(environment: environment)
        case .post:
            PostRequestView(environment: environment) { request in
                newlyPostedID = request.id
                selection = .activity
            }
        case .activity:
            ActivityView(environment: environment, highlightedRequestID: newlyPostedID)
        case .profile:
            ProfileView(environment: environment)
        case .devSettings:
            DevSettingsView()
        }
    }
}

#Preview {
    MainTabView()
}
