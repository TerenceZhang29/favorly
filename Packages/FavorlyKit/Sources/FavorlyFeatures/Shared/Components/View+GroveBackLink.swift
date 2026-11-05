import SwiftUI

extension View {
    /// Replaces the back button with the mockup's "‹ Nearby" link.
    func groveBackLink() -> some View {
        modifier(GroveBackLinkModifier())
    }
}
