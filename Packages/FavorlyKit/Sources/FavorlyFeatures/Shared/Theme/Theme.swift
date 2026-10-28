import Foundation

/// The one source of style. Screens take every color, spacing and corner radius from here.
enum Theme {
    enum Colors {
        /// Tint: buttons, links, the selected tab, "New" and "Yours" badges, distance.
        static let brand = AdaptiveColor(light: 0x0A6B67, dark: 0x4FD1C5)
        /// Label on a solid `brand` fill.
        static let onBrand = AdaptiveColor(light: 0xFFFFFF, dark: 0x000000)
        static let categoryIngredient = AdaptiveColor(light: 0x286E2C, dark: 0x6FCF7A)
        static let categoryMoving = AdaptiveColor(light: 0x4B4FC4, dark: 0x9FA3FF)
        static let categoryCar = AdaptiveColor(light: 0x195EB6, dark: 0x6FB1FF)
        static let categoryErrand = AdaptiveColor(light: 0xAB2D5E, dark: 0xFF8FB3)
        /// The Other category and the Completed status.
        static let neutral = AdaptiveColor(light: 0x5A616C, dark: 0xA9B0BC)
        static let statusOpen = brand
        static let statusClaimed = AdaptiveColor(light: 0x974B00, dark: 0xFFB357)
        /// Cancelled status, destructive actions and error text.
        static let statusCancelled = AdaptiveColor(light: 0xB42424, dark: 0xFF8A80)

        /// Every color that is shown as a foreground on a soft tint of itself.
        static let palette = [
            brand, categoryIngredient, categoryMoving, categoryCar, categoryErrand,
            neutral, statusOpen, statusClaimed, statusCancelled,
        ]

        /// The colors an avatar can take: the colorful palette entries, without the gray or the status colors.
        static let avatars = [brand, categoryIngredient, categoryMoving, categoryCar, categoryErrand]
    }

    enum Spacing {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xLarge: CGFloat = 16
        static let section: CGFloat = 24
        /// Space kept free on the far side of a chat bubble, so the two people's messages read as two columns.
        static let bubbleInset: CGFloat = 48
    }

    /// Height of Apple's Sign in with Apple button, which draws itself and needs an explicit size.
    static let appleButtonHeight: CGFloat = 50

    enum Radius {
        static let badge: CGFloat = 6
        static let tile: CGFloat = 10
        static let button: CGFloat = 12
        /// Chat message bubbles.
        static let bubble: CGFloat = 18
    }

    /// Side of a `CategoryIcon` tile at the default text size.
    enum IconSize {
        static let row: CGFloat = 36
        static let large: CGFloat = 56
        /// Side of the avatar circle on a profile.
        static let avatar: CGFloat = 64
        /// Size of the symbol as a share of the tile's side.
        static let symbolScale: CGFloat = 0.5
        /// The most a tile grows with Dynamic Type, as a multiple of its default side.
        static let maxScale: CGFloat = 2
    }

    /// Opacity of the soft background behind a colored element.
    static let tintOpacity = 0.14
    /// Opacity of the brand color behind a highlighted list row. Lower than `tintOpacity` so badges stay readable.
    static let highlightOpacity = 0.08
    static let pressedOpacity = 0.7
    static let disabledOpacity = 0.4
}
