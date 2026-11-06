import SwiftUI

/// Draws a `GroveShadow` under a view, or nothing when its strength is zero in this color scheme.
struct GroveShadowModifier: ViewModifier {
    let shadow: GroveShadow
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if Theme.drawsShadows {
            shadowed(content)
        } else {
            content
        }
    }

    private func shadowed(_ content: Content) -> some View {
        content.shadow(
            color: shadow.color.color(for: colorScheme).opacity(shadow.opacity(for: colorScheme)),
            radius: shadow.radius / 2,
            y: shadow.offsetY
        )
    }
}
