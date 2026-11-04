import SwiftUI

/// A soft drop shadow in a theme color, with its own strength in light and dark mode.
struct GroveShadow: Hashable, Sendable {
    let color: AdaptiveColor
    let lightOpacity: Double
    let darkOpacity: Double
    let radius: CGFloat
    let offsetY: CGFloat

    func opacity(for colorScheme: ColorScheme) -> Double {
        colorScheme == .dark ? darkOpacity : lightOpacity
    }
}
