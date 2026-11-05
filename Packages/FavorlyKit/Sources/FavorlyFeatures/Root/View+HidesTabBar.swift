import SwiftUI

extension View {
    /// Hides the Grove tab bar while this screen is on top of its tab, as the mockup's chat does.
    func hidesTabBar() -> some View {
        modifier(HidesTabBarModifier())
    }
}
