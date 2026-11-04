import SwiftUI

/// A user's initial on a calm circle. Stands in for a profile photo.
/// Grows with Dynamic Type, up to `Theme.IconSize.maxScale`.
struct AvatarView: View {
    let name: String
    private let baseSide: CGFloat
    @ScaledMetric private var scaledSide: CGFloat

    init(name: String, side: CGFloat = Theme.IconSize.avatar) {
        self.name = name
        baseSide = side
        _scaledSide = ScaledMetric(wrappedValue: side)
    }

    private var side: CGFloat { min(scaledSide, baseSide * Theme.IconSize.maxScale) }

    private var initial: String {
        name.first.map { String($0).uppercased() } ?? "?"
    }

    var body: some View {
        Text(initial)
            .font(.custom(GroveFonts.bold, fixedSize: side * Theme.IconSize.initialScale))
            .foregroundStyle(Theme.Colors.onAvatar)
            .frame(width: side, height: side)
            .background(Theme.Colors.avatar, in: Circle())
            .accessibilityHidden(true)
    }
}

#Preview {
    LightAndDarkPreview {
        AvatarView(name: "Bea")
        AvatarView(name: "Chen", side: Theme.IconSize.row)
    }
}
