import SwiftUI

/// A color with a light and a dark value. Use it anywhere a `ShapeStyle` is accepted.
struct AdaptiveColor: ShapeStyle, Hashable, Sendable {
    let light: RGBColor
    let dark: RGBColor

    init(light: RGBColor, dark: RGBColor) {
        self.light = light
        self.dark = dark
    }

    init(light: UInt32, dark: UInt32) {
        self.init(light: RGBColor(hex: light), dark: RGBColor(hex: dark))
    }

    func rgb(for colorScheme: ColorScheme) -> RGBColor {
        colorScheme == .dark ? dark : light
    }

    func resolve(in environment: EnvironmentValues) -> Color {
        color(for: environment.colorScheme)
    }

    /// The plain SwiftUI color for one color scheme, for places that take a `Color`, such as a shadow.
    func color(for colorScheme: ColorScheme) -> Color {
        let rgb = rgb(for: colorScheme)
        return Color(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}
