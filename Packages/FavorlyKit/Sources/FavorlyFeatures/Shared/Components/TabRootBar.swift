import SwiftUI

/// Hides the navigation bar on a tab's first screen, which shows its own header, and leaves it on pushed
/// copies of the same screen, such as someone else's profile.
struct TabRootBar: ViewModifier {
    let isTabRoot: Bool

    func body(content: Content) -> some View {
        if isTabRoot {
            content.hidingNavigationBar()
        } else {
            content
        }
    }
}
