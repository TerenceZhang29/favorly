import SwiftUI

/// A symbol on a rounded square in the olive tint. Grows with Dynamic Type, up to
/// `Theme.IconSize.maxScale`, so the text beside it keeps most of the row at the largest text sizes.
struct IconTile: View {
    let systemImage: String
    private let baseSide: CGFloat
    @ScaledMetric private var scaledSide: CGFloat

    init(systemImage: String, isLarge: Bool = false) {
        self.systemImage = systemImage
        baseSide = isLarge ? Theme.IconSize.large : Theme.IconSize.row
        _scaledSide = ScaledMetric(wrappedValue: baseSide)
    }

    private var side: CGFloat { min(scaledSide, baseSide * Theme.IconSize.maxScale) }

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: side * Theme.IconSize.symbolScale, weight: .medium))
            .foregroundStyle(Theme.Colors.onTint)
            .frame(width: side, height: side)
            .background(Theme.Colors.tint, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    LightAndDarkPreview {
        HStack(spacing: Theme.Spacing.large) {
            ForEach(["carrot", "shippingbox", "car", "bag", "hand.raised"], id: \.self) { symbol in
                IconTile(systemImage: symbol)
            }
        }
        IconTile(systemImage: "carrot", isLarge: true)
    }
}
