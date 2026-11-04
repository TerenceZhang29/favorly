/// The colors of a badge: its fill, its text, and an outline for badges that have no fill of their own.
struct BadgeColors: Hashable, Sendable {
    let fill: AdaptiveColor
    let text: AdaptiveColor
    var outline: AdaptiveColor?

    /// "Yours" and the Open status: good news, on lime.
    static let lime = BadgeColors(fill: Theme.Colors.lime, text: Theme.Colors.onLime)
    /// "Claimed" and "Helped": on the soft olive tint.
    static let tint = BadgeColors(fill: Theme.Colors.tint, text: Theme.Colors.onTint)
    /// "Completed" and "Asked": quiet.
    static let quiet = BadgeColors(fill: Theme.Colors.segment, text: Theme.Colors.ink)
    /// "Cancelled": an outline only, in muted ink.
    static let outline = BadgeColors(
        fill: Theme.Colors.surface,
        text: Theme.Colors.inkMuted,
        outline: Theme.Colors.inkMuted
    )
    /// "New": the one warm accent.
    static let spark = BadgeColors(fill: Theme.Colors.spark, text: Theme.Colors.onSpark)
}
