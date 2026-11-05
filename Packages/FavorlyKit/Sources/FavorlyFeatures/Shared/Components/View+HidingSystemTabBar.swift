import SwiftUI

extension View {
    /// Hides the system tab bar for this tab, which shows the Grove tab bar instead. Only iOS has the setting.
    func hidingSystemTabBar() -> some View {
        #if os(iOS)
            toolbar(.hidden, for: .tabBar)
        #else
            self
        #endif
    }
}
