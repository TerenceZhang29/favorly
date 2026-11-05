import SwiftUI

extension View {
    /// Keeps the navigation title for the back button and VoiceOver but doesn't draw it in the bar.
    /// iOS 17 still draws it; the system option to remove it starts with iOS 18.
    @ViewBuilder
    func hidingNavigationTitle() -> some View {
        if #available(iOS 18, macOS 15, *) {
            toolbar(removing: .title)
        } else {
            self
        }
    }
}
