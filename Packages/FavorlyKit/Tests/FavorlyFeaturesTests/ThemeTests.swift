import FavorlyCore
@testable import FavorlyFeatures
import SwiftUI
import Testing

struct ThemeTests {
    /// Spelled out because macOS has an old system type with the same name.
    private typealias RGBColor = FavorlyFeatures.RGBColor

    /// WCAG AA for normal-size text.
    private let minimumContrast = 4.5

    /// A text color, a fill it sits on, and what it is, for the failure message.
    struct Pair: CustomTestStringConvertible, Sendable {
        let text: AdaptiveColor
        let fill: AdaptiveColor
        let name: String
        var testDescription: String { name }
    }

    private typealias Palette = Theme.Colors

    /// Every pairing of text on a fill that the screens and components use.
    static let pairs: [Pair] = [
        Pair(text: Palette.ink, fill: Palette.background, name: "ink on background"),
        Pair(text: Palette.ink, fill: Palette.surface, name: "ink on surface"),
        Pair(text: Palette.ink, fill: Palette.tint, name: "ink on a highlighted card"),
        Pair(text: Palette.ink, fill: Palette.segment, name: "Completed and Asked badges"),
        Pair(text: Palette.inkMuted, fill: Palette.background, name: "muted ink on background"),
        Pair(text: Palette.inkMuted, fill: Palette.surface, name: "muted ink on surface"),
        Pair(text: Palette.inkMuted, fill: Palette.tint, name: "muted ink on a highlighted card"),
        Pair(text: Palette.inkMuted, fill: Palette.segment, name: "disabled primary button label"),
        Pair(text: Palette.brand, fill: Palette.background, name: "links on background"),
        Pair(text: Palette.brand, fill: Palette.surface, name: "links on surface"),
        Pair(text: Palette.onBrand, fill: Palette.brand, name: "primary button label"),
        Pair(text: Palette.onLime, fill: Palette.lime, name: "Open and Yours badges"),
        Pair(text: Palette.onTint, fill: Palette.tint, name: "Claimed, Helped, secondary buttons, icon tiles"),
        Pair(text: Palette.onSpark, fill: Palette.spark, name: "New badge"),
        Pair(text: Palette.points, fill: Palette.surface, name: "points on a card"),
        Pair(text: Palette.points, fill: Palette.tint, name: "points on a highlighted card"),
        Pair(text: Palette.danger, fill: Palette.background, name: "errors on background"),
        Pair(text: Palette.danger, fill: Palette.surface, name: "errors on surface"),
        Pair(text: Palette.danger, fill: Palette.dangerTint, name: "danger buttons and banners"),
        Pair(text: Palette.onAvatar, fill: Palette.avatar, name: "avatar initials"),
        Pair(text: Palette.onBubbleMine, fill: Palette.bubbleMine, name: "the user's own chat bubbles"),
        Pair(text: Palette.onBanner, fill: Palette.banner, name: "the message banner's text and Later"),
        Pair(text: Palette.bannerAccent, fill: Palette.banner, name: "the favor's name on the message banner"),
        Pair(text: Palette.bannerMuted, fill: Palette.banner, name: "the time on the message banner"),
        Pair(text: Palette.onBannerButton, fill: Palette.bannerButton, name: "the banner's Reply button"),
    ]

    @Test(arguments: pairs, [ColorScheme.light, .dark])
    func textIsReadableOnItsFill(pair: Pair, colorScheme: ColorScheme) {
        let ratio = pair.text.rgb(for: colorScheme).contrastRatio(with: pair.fill.rgb(for: colorScheme))
        #expect(ratio >= minimumContrast, "\(pair.name) in \(colorScheme): \(ratio)")
    }

    /// Later on the message banner is only an outline, so it must be visible against the banner (3:1).
    @Test(arguments: [ColorScheme.light, .dark])
    func theBannersLaterOutlineIsVisible(colorScheme: ColorScheme) {
        let ratio = Palette.bannerOutline.rgb(for: colorScheme)
            .contrastRatio(with: Palette.banner.rgb(for: colorScheme))
        #expect(ratio >= 3, "\(colorScheme): \(ratio)")
    }

    /// The Cancelled badge has no fill of its own, so its outline must be visible against a card (3:1 for
    /// non-text elements).
    @Test(arguments: [ColorScheme.light, .dark])
    func theCancelledOutlineIsVisible(colorScheme: ColorScheme) throws {
        let outline = try #require(BadgeColors.outline.outline)
        #expect(outline.rgb(for: colorScheme).contrastRatio(with: Palette.surface.rgb(for: colorScheme)) >= 3)
    }

    /// Every badge's text is readable on its own fill.
    @Test(arguments: [BadgeColors.lime, .tint, .quiet, .outline, .spark], [ColorScheme.light, .dark])
    func everyBadgeIsReadable(colors: BadgeColors, colorScheme: ColorScheme) {
        let ratio = colors.text.rgb(for: colorScheme).contrastRatio(with: colors.fill.rgb(for: colorScheme))
        #expect(ratio >= minimumContrast)
    }

    @Test func adaptiveColorPicksTheValueForTheColorScheme() {
        let color = AdaptiveColor(light: 0x6B6D18, dark: 0xD6EF4F)
        #expect(color.rgb(for: .light) == RGBColor(hex: 0x6B6D18))
        #expect(color.rgb(for: .dark) == RGBColor(hex: 0xD6EF4F))
    }

    @Test func theGroveColorsMatchThePlan() {
        #expect(Palette.background == AdaptiveColor(light: 0xF8FAE6, dark: 0x141A0D))
        #expect(Palette.brand == AdaptiveColor(light: 0x6B6D18, dark: 0xD6EF4F))
        #expect(Palette.lime == AdaptiveColor(light: 0xD6EF4F, dark: 0xD6EF4F))
        #expect(Palette.ink == AdaptiveColor(light: 0x1D2B12, dark: 0xF1F5E1))
    }

    @Test func everyStatusMapsToItsBadge() {
        #expect(RequestStatus.open.badgeColors == .lime)
        #expect(RequestStatus.claimed.badgeColors == .tint)
        #expect(RequestStatus.completed.badgeColors == .quiet)
        #expect(RequestStatus.cancelled.badgeColors == .outline)
        let statuses: [RequestStatus] = [.open, .claimed, .completed, .cancelled]
        #expect(Set(statuses.map(\.badgeColors)).count == statuses.count)
    }

    @Test func spacingAndRadiusMatchThePlan() {
        #expect(Theme.Spacing.screen == 20)
        #expect(Theme.Spacing.card == 16)
        #expect(Theme.Radius.card == 22)
        #expect(Theme.Radius.button == 18)
        #expect(Theme.Radius.field == 14)
        #expect(Theme.Radius.tile == 12)
        #expect(Theme.controlHeight == 56)
    }

    @Test func theTypeScaleMatchesThePlan() {
        #expect(TextStyle.largeTitle.size == 34)
        #expect(TextStyle.title.size == 28)
        #expect(TextStyle.cardTitle.size == 19)
        #expect(TextStyle.body.size == 15)
        #expect(TextStyle.meta.size == 13)
        #expect(TextStyle.badge.size == 11)
        #expect(TextStyle.badge.isUppercase)
        #expect(TextStyle.allCases.allSatisfy { GroveFonts.all.contains($0.fontName) })
    }

    /// The Figtree files are bundled with the module and register, so `Font.custom` finds them.
    @Test func figtreeIsBundledAndRegisters() {
        #expect(GroveFonts.registered)
        #if canImport(CoreText)
            for name in GroveFonts.all {
                let font = CTFontCreateWithName(name as CFString, 12, nil)
                #expect(CTFontCopyPostScriptName(font) as String == name)
            }
        #endif
    }
}
