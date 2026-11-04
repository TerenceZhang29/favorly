import SwiftUI

/// The Grove type scale, set in Figtree. Every style scales with Dynamic Type through the system text style
/// it is relative to. Apply one with `.textStyle(_:)`, which also sets its letter spacing and case.
enum TextStyle: CaseIterable, Sendable {
    /// Root screen titles: 34 Bold.
    case largeTitle
    /// Request Detail title, profile name: 28 Bold.
    case title
    /// A request's title on a card: 19 Medium.
    case cardTitle
    /// Section headers, sheet titles: 17 Bold.
    case headline
    /// Details, chat messages, fields: 15 Regular.
    case body
    /// Row titles and names: 15 SemiBold.
    case bodyStrong
    /// The distance · name · time line: 13 Regular.
    case meta
    /// Small meta text that needs weight, such as the time a chat message was sent: 13 SemiBold.
    case metaStrong
    /// Buttons: 16 Bold.
    case button
    /// Status and tag badges: 11 Bold, upper case.
    case badge
    /// The Kindness score on a profile: 38 Bold.
    case score

    var font: Font {
        GroveFonts.registerIfNeeded()
        return Font.custom(fontName, size: size, relativeTo: relativeTo)
    }

    var fontName: String {
        switch self {
        case .largeTitle, .title, .headline, .button, .badge, .score: GroveFonts.bold
        case .bodyStrong, .metaStrong: GroveFonts.semiBold
        case .cardTitle: GroveFonts.medium
        case .body, .meta: GroveFonts.regular
        }
    }

    var size: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title: 28
        case .cardTitle: 19
        case .headline: 17
        case .body, .bodyStrong: 15
        case .meta, .metaStrong: 13
        case .button: 16
        case .badge: 11
        case .score: 38
        }
    }

    var relativeTo: Font.TextStyle {
        switch self {
        case .largeTitle, .score: .largeTitle
        case .title: .title
        case .cardTitle: .title3
        case .headline: .headline
        case .body, .bodyStrong: .subheadline
        case .meta, .metaStrong: .footnote
        case .button: .callout
        case .badge: .caption2
        }
    }

    /// Letter spacing as a share of the size: tighter for big titles, looser for small capitals.
    var trackingFactor: CGFloat {
        switch self {
        case .largeTitle, .title, .score: -0.02
        case .badge: 0.08
        default: 0
        }
    }

    var isUppercase: Bool { self == .badge }
}
