import FavorlyCore
import SwiftUI

/// The app's tabs, for a signed-in user: one navigation stack per tab, and the mockup's floating Grove tab bar
/// at the bottom in place of the system one. The bar steps aside while the keyboard is up and
/// while a screen hides it (Chat). A banner slides down over every tab when a message arrives.
struct MainTabView: View {
    @Environment(\.appEnvironment) private var environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection: RootTab = .nearby
    /// The user's conversations: the Messages tab, its badge and the banner.
    @State private var inbox: InboxModel
    /// The request just posted, highlighted in My Activity until the user leaves that tab.
    @State private var newlyPostedID: RequestID?
    /// My Activity's stack, which opens tapped notifications.
    @State private var activityPath = NavigationPath()
    /// The Messages tab's stack, which opens a chat from the banner or a message notification.
    @State private var messagesPath = NavigationPath()
    @State private var otherPaths: [RootTab: NavigationPath] = [:]
    @State private var tabBarVisibility = TabBarVisibility()
    @State private var isKeyboardShown = false

    init(environment: AppEnvironment) {
        _inbox = State(initialValue: InboxModel(environment: environment))
    }

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
                GroveTabBar(tabs: RootTab.visible, selection: $selection, badges: badges)
            }
        }
        .overlay(alignment: .top) {
            if let message = inbox.banner {
                IncomingMessageBanner(message: message) {
                    reply(to: message)
                } onLater: {
                    inbox.dismissBanner()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .task(id: message) {
                    try? await Task.sleep(for: InboxModel.bannerDuration)
                    inbox.bannerTimedOut(message)
                }
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: inbox.banner)
        .environment(\.inbox, inbox)
        .task(id: inbox.reloadKey) { await inbox.load() }
        .task { await inbox.observeChanges() }
        .onChange(of: environment.router.foregroundMessages) {
            Task { await inbox.load() }
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

    private var badges: [RootTab: String] {
        inbox.badgeText.map { [.messages: $0] } ?? [:]
    }

    private func path(for tab: RootTab) -> Binding<NavigationPath> {
        switch tab {
        case .activity: return $activityPath
        case .messages: return $messagesPath
        default: break
        }
        return Binding(
            get: { otherPaths[tab] ?? NavigationPath() },
            set: { otherPaths[tab] = $0 }
        )
    }

    /// Shows a tapped notification: a request in My Activity, a message's chat in Messages.
    private func open(_ route: NotificationRoute) {
        switch route {
        case let .request(id):
            selection = .activity
            activityPath = NavigationPath([id])
        case let .chat(id):
            openChat(id)
        }
    }

    /// The banner's Reply: the chat, on the Messages tab.
    private func reply(to message: IncomingMessage) {
        inbox.dismissBanner()
        openChat(message.requestID)
    }

    private func openChat(_ id: RequestID) {
        selection = .messages
        messagesPath = NavigationPath([ChatDestination(requestID: id)])
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
        case .messages:
            InboxView(model: inbox)
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
    MainTabView(environment: .sharedPreview)
}
