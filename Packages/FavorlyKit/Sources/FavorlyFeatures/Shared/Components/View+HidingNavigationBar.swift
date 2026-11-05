import SwiftUI

extension View {
    /// Hides the navigation bar on a tab's first screen, which shows the mockup's headline instead. The
    /// title stays set, for VoiceOver and the back link of the next screen. Only iOS has the setting.
    func hidingNavigationBar() -> some View {
        #if os(iOS)
            toolbar(.hidden, for: .navigationBar)
        #else
            self
        #endif
    }
}
