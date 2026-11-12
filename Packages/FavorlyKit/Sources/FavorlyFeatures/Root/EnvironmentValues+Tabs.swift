import SwiftUI

extension EnvironmentValues {
    /// The tab the view is in, or nil outside the tabs (onboarding, previews).
    @Entry var currentTab: RootTab?
    /// Switches to another tab, such as the Nearby score pill opening Profile. Does nothing outside the tabs.
    @Entry var selectTab = SelectTabAction()
    /// Lets a screen hide the tab bar while it shows, such as Chat with its message field.
    @Entry var tabBarVisibility: TabBarVisibility?
    /// The user's conversations, so Chat can say which thread is on screen. Nil outside the tabs.
    @Entry var inbox: InboxModel?
}
