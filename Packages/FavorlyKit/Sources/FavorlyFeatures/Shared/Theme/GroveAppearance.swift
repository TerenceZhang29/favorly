#if canImport(UIKit)
    import SwiftUI
    import UIKit

    /// Grove fonts and colors for the parts SwiftUI draws with UIKit: navigation bar titles, tab bar labels
    /// and segmented pickers. Applied once, before the first screen appears.
    @MainActor
    enum GroveAppearance {
        private static var isApplied = false

        static func applyIfNeeded() {
            guard !isApplied else { return }
            isApplied = true
            GroveFonts.registerIfNeeded()
            applyNavigationBar()
            applyTabBar()
            applySegmentedControl()
        }

        private static func applyNavigationBar() {
            let ink = uiColor(Theme.Colors.ink)
            let titles: (UINavigationBarAppearance) -> Void = { appearance in
                appearance.largeTitleTextAttributes = [
                    .font: font(.largeTitle),
                    .foregroundColor: ink,
                    .kern: TextStyle.largeTitle.size * TextStyle.largeTitle.trackingFactor,
                ]
                appearance.titleTextAttributes = [.font: font(.headline), .foregroundColor: ink]
            }
            let scrollEdge = UINavigationBarAppearance()
            scrollEdge.configureWithTransparentBackground()
            titles(scrollEdge)
            let standard = UINavigationBarAppearance()
            standard.configureWithDefaultBackground()
            titles(standard)
            let bar = UINavigationBar.appearance()
            bar.standardAppearance = standard
            bar.compactAppearance = standard
            bar.scrollEdgeAppearance = scrollEdge
            UIBarButtonItem.appearance().setTitleTextAttributes([.font: font(.bodyStrong, size: 17)], for: .normal)
        }

        private static func applyTabBar() {
            let item = UITabBarItem.appearance()
            item.setTitleTextAttributes([.font: font(.metaStrong, size: 10)], for: .normal)
        }

        private static func applySegmentedControl() {
            let control = UISegmentedControl.appearance()
            control.selectedSegmentTintColor = uiColor(Theme.Colors.surface, dark: Theme.Colors.ink)
            control.backgroundColor = uiColor(Theme.Colors.segment)
            control.setTitleTextAttributes(
                [.font: font(.bodyStrong, size: 13), .foregroundColor: uiColor(Theme.Colors.inkMuted)],
                for: .normal
            )
            control.setTitleTextAttributes(
                [
                    .font: font(.headline, size: 13),
                    .foregroundColor: uiColor(Theme.Colors.ink, dark: Theme.Colors.background),
                ],
                for: .selected
            )
        }

        /// The Figtree face of `style`, scaled for the user's text size like the SwiftUI style.
        private static func font(_ style: TextStyle, size: CGFloat? = nil) -> UIFont {
            let base = UIFont(name: style.fontName, size: size ?? style.size)
                ?? .systemFont(ofSize: size ?? style.size, weight: .semibold)
            return UIFontMetrics(forTextStyle: uiTextStyle(style.relativeTo)).scaledFont(for: base)
        }

        private static func uiTextStyle(_ style: Font.TextStyle) -> UIFont.TextStyle {
            switch style {
            case .largeTitle: .largeTitle
            case .title: .title1
            case .title3: .title3
            case .headline: .headline
            case .subheadline: .subheadline
            case .footnote: .footnote
            case .callout: .callout
            case .caption2: .caption2
            default: .body
            }
        }

        /// A UIKit color that follows light and dark mode. `dark`, when given, replaces the token's dark value.
        private static func uiColor(_ color: AdaptiveColor, dark: AdaptiveColor? = nil) -> UIColor {
            UIColor { traits in
                let rgb = traits.userInterfaceStyle == .dark ? (dark ?? color).dark : color.light
                return UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
            }
        }
    }
#endif
