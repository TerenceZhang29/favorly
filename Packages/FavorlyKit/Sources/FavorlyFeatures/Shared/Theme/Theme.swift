import SwiftUI

/// The one source of style. Screens take every color, font, spacing, corner radius and shadow from here.
/// The values are the Grove look in `docs/PLAN-PHASE-5.md`.
enum Theme {
    enum Colors {
        /// Screen background behind lists and forms.
        static let background = AdaptiveColor(light: 0xF8FAE6, dark: 0x141A0D)
        /// Cards, list rows and text fields.
        static let surface = AdaptiveColor(light: 0xFFFFFF, dark: 0x22281C)
        /// The thin outline around a card or field.
        static let surfaceBorder = AdaptiveColor(light: 0xE5E9CF, dark: 0x2C3125)
        /// Row separators.
        static let divider = AdaptiveColor(light: 0xE5E9CF, dark: 0x272C20)
        /// Primary text.
        static let ink = AdaptiveColor(light: 0x1D2B12, dark: 0xF1F5E1)
        /// Secondary text: meta lines, footers, empty states.
        static let inkMuted = AdaptiveColor(light: 0x586048, dark: 0xA6AE91)
        /// Tint: buttons, links, the selected tab, back buttons.
        static let brand = AdaptiveColor(light: 0x6B6D18, dark: 0xD6EF4F)
        /// Label on a solid `brand` fill.
        static let onBrand = AdaptiveColor(light: 0xFFFFFF, dark: 0x141A0D)
        /// Good news: the Open status, "Yours", the Kindness score badge.
        static let lime = AdaptiveColor(light: 0xD6EF4F, dark: 0xD6EF4F)
        static let onLime = AdaptiveColor(light: 0x1D2B12, dark: 0x141A0D)
        /// Soft fill: category tiles, secondary buttons, the Claimed status, a highlighted row.
        static let tint = AdaptiveColor(light: 0xEAF2BF, dark: 0x2D3616)
        static let onTint = AdaptiveColor(light: 0x45470C, dark: 0xDDF27A)
        /// Point values and the score heart.
        static let points = AdaptiveColor(light: 0x5C5E12, dark: 0xD6EF4F)
        /// A quiet fill: the Completed status, "Asked", a disabled primary button.
        static let segment = AdaptiveColor(light: 0xECEFD6, dark: 0x30352A)
        /// The "New" badge.
        static let spark = AdaptiveColor(light: 0xE8701F, dark: 0xFF8A3D)
        /// Text on `spark`. White on the light value would be only about 3:1.
        static let onSpark = AdaptiveColor(light: 0x1D2B12, dark: 0x141A0D)
        /// Cancel request, Delete account, error text.
        static let danger = AdaptiveColor(light: 0xB3261E, dark: 0xFF8A80)
        /// Soft fill behind a danger button or banner.
        static let dangerTint = AdaptiveColor(light: 0xF8E1DC, dark: 0x3A2420)
        /// Avatar circle and initials. Everyone gets the same calm color.
        static let avatar = AdaptiveColor(light: 0xECE9DF, dark: 0x2A321F)
        static let onAvatar = AdaptiveColor(light: 0x3A4230, dark: 0xE3E8D0)
        /// Filled stars.
        static let star = AdaptiveColor(light: 0x8DA81A, dark: 0xD6EF4F)
        /// Empty star outlines and other decorative strokes.
        static let starEmpty = AdaptiveColor(light: 0x9AA283, dark: 0x6E7760)
        /// The dark-mode glow behind the top of a screen. Light mode has none.
        static let glow = AdaptiveColor(light: 0xF8FAE6, dark: 0x2A3510)
        /// The chat bubble of the signed-in user, and its text.
        static let bubbleMine = ink
        static let onBubbleMine = AdaptiveColor(light: 0xF8FAE6, dark: 0x141A0D)
    }

    enum Spacing {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xLarge: CGFloat = 16
        /// Space around a card's content.
        static let card: CGFloat = 16
        /// The left and right margin of a screen's cards.
        static let screen: CGFloat = 20
        static let section: CGFloat = 24
        /// The gap between two cards in a list.
        static let cardGap: CGFloat = 6
        /// Space kept free on the far side of a chat bubble, so the two people's messages read as two columns.
        static let bubbleInset: CGFloat = 48
    }

    /// Height of Apple's Sign in with Apple button, which draws itself and needs an explicit size.
    static let appleButtonHeight: CGFloat = 56

    enum Radius {
        /// Request cards and profile cards.
        static let card: CGFloat = 22
        /// The primary button, 56 points tall.
        static let button: CGFloat = 18
        /// Text fields and banners.
        static let field: CGFloat = 14
        /// A category tile.
        static let tile: CGFloat = 12
        /// Chat bubbles, with a smaller corner on the sender's side.
        static let bubble: CGFloat = 18
        static let bubbleTail: CGFloat = 6
        /// The top corners of a sheet.
        static let sheet: CGFloat = 28
    }

    enum IconSize {
        /// Side of a `CategoryIcon` tile in a row, at the default text size.
        static let row: CGFloat = 38
        static let large: CGFloat = 56
        /// The largest a star button on the review form gets, so five fit across the narrowest phone.
        static let starMax: CGFloat = 60
        /// Side of the symbol tile on a fact row.
        static let fact: CGFloat = 32
        /// Side of the avatar circle on a profile.
        static let avatar: CGFloat = 84
        /// Size of the symbol as a share of the tile's side.
        static let symbolScale: CGFloat = 0.5
        /// Size of an avatar's initial as a share of the circle's side.
        static let initialScale: CGFloat = 0.4
        /// The most a tile grows with Dynamic Type, as a multiple of its default side.
        static let maxScale: CGFloat = 2
        /// Size of the dark-mode glow.
        static let glow: CGFloat = 360
    }

    enum Shadow {
        /// Under a card, light mode only.
        static let card = GroveShadow(color: Colors.ink, lightOpacity: 0.06, darkOpacity: 0, radius: 20, offsetY: 6)
        /// Under the primary button.
        static let primary = GroveShadow(
            color: Colors.brand,
            lightOpacity: 0.3,
            darkOpacity: 0.22,
            radius: 26,
            offsetY: 10
        )
        static let none = GroveShadow(color: Colors.ink, lightOpacity: 0, darkOpacity: 0, radius: 0, offsetY: 0)
    }

    /// The largest text size a section header follows.
    static let headerMaxTypeSize = DynamicTypeSize.accessibility2
    /// Blur of the dark-mode glow.
    static let glowBlur: CGFloat = 70
    static let glowOpacity = 0.7
    /// Height of the primary button and the chat composer's controls.
    static let controlHeight: CGFloat = 56
    static let composerHeight: CGFloat = 48
    static let borderWidth: CGFloat = 1
    static let pressedOpacity = 0.7
    static let disabledOpacity = 0.5
}
