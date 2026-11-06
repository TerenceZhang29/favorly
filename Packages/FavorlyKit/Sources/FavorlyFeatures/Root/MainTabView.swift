import FavorlyCore
import SwiftUI

/// The app's tabs, for a signed-in user: one navigation stack per tab, and the mockup's floating Grove tab bar
/// at the bottom in place of the system one. The bar steps aside while the keyboard is up and
/// while a screen hides it (Chat).
struct MainTabView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var selection: RootTab = .nearby
    /// The request just posted, highlighted in My Activity until the user leaves that tab.
    @State private var newlyPostedID: RequestID?
    /// My Activity's stack, which opens tapped notifications.
    @State private var activityPath = NavigationPath()
    @State private var otherPaths: [RootTab: NavigationPath] = [:]
    @State private var tabBarVisibility = TabBarVisibility()
    @State private var isKeyboardShown = false

    var body: some View {
        // The system tab view keeps each tab's place and draws only the selected one; its own bar is hidden,
        // and the Grove bar sits on top instead.
        TabView(selection: $selection) {
            ForEach(RootTab.visible) { tab in
                NavigationStack(path: path(for: tab)) {
                    content(for: tab)
                        .appDestinations(environment)
                }
                .environment(\.currentTab, tab)
                // Room for the floating bar, given to each tab's stack so every screen in it, pushed ones too,
                // can scroll its last items clear of the bar.
                .safeAreaPadding(.bottom, showsTabBar ? Theme.tabBarSpace : 0)
                .hidingSystemTabBar()
                // Without the system bar, iOS can leave visited tabs in the accessibility tree.
                .accessibilityHidden(tab != selection)
                .tag(tab)
                .accessibilityIdentifier("root.tab.\(tab.rawValue)")
            }
        }
        .overlay(alignment: .bottom) {
            if showsTabBar {
                GroveTabBar(tabs: RootTab.visible, selection: $selection)
            }
        }
        .environment(\.tabBarVisibility, tabBarVisibility)
        .environment(\.selectTab, SelectTabAction { tab in selection = tab })
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
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardShown = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardShown = false
        }
        #endif
    }

    private var showsTabBar: Bool {
        !isKeyboardShown && !tabBarVisibility.isHidden(for: selection)
    }

    private func path(for tab: RootTab) -> Binding<NavigationPath> {
        if tab == .activity {
            return $activityPath
        }
        return Binding(
            get: { otherPaths[tab] ?? NavigationPath() },
            set: { otherPaths[tab] = $0 }
        )
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
