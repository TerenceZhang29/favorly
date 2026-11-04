import SwiftUI

extension View {
    /// Draws `shadow` under the view, or nothing when its strength is zero in this color scheme.
    func groveShadow(_ shadow: GroveShadow) -> some View {
        modifier(GroveShadowModifier(shadow: shadow))
    }
}
