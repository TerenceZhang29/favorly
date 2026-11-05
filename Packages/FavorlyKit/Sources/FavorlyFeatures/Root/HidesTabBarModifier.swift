import SwiftUI

/// Hides the tab bar for the screen's tab while the screen shows, and brings it back when it goes away.
struct HidesTabBarModifier: ViewModifier {
    @Environment(\.currentTab) private var currentTab
    @Environment(\.tabBarVisibility) private var visibility

    func body(content: Content) -> some View {
        content
            .onAppear { update(hidden: true) }
            .onDisappear { update(hidden: false) }
    }

    private func update(hidden: Bool) {
        guard let currentTab else { return }
        visibility?.setHidden(hidden, for: currentTab)
    }
}
