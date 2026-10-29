import FavorlyCore
import SwiftUI

/// The app's tabs, for a signed-in user.
struct MainTabView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var selection: RootTab = .nearby
    /// The request just posted, highlighted in My Activity until the user leaves that tab.
    @State private var newlyPostedID: RequestID?
    /// My Activity's stack, which opens tapped notifications.
    @State private var activityPath = NavigationPath()

    var body: some View {
        TabView(selection: $selection) {
            ForEach(RootTab.visible) { tab in
                NavigationStack(path: tab == .activity ? $activityPath : .constant(NavigationPath())) {
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
        .onChange(of: environment.router.pending, initial: true) { _, route in
            guard let route else { return }
            open(route)
            environment.router.pending = nil
        }
    }

    /// Shows a tapped notification in My Activity: the request, and its chat on top for a message.
    private func open(_ route: NotificationRoute) {
        var path = NavigationPath()
        switch route {
        case let .request(id):
            path.append(id)
        case let .chat(id):
            path.append(id)
            path.append(ChatDestination(requestID: id))
        }
        selection = .activity
        activityPath = path
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
