import SwiftUI

/// A label and its value, side by side, or stacked at accessibility text sizes. VoiceOver reads them as one item.
struct FactRow: View {
    let label: String
    let value: String
    /// An optional SF Symbol shown before the label, on a small olive tile.
    var systemImage: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric private var scaledTileSide = Theme.IconSize.fact

    /// Grows with the text, but no more than `Theme.IconSize.maxScale`, so the label keeps most of the row.
    private var tileSide: CGFloat { min(scaledTileSide, Theme.IconSize.fact * Theme.IconSize.maxScale) }

    var body: some View {
        HStack(spacing: Theme.Spacing.large) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: tileSide * Theme.IconSize.symbolScale, weight: .medium))
                    .foregroundStyle(Theme.Colors.onTint)
                    .frame(width: tileSide, height: tileSide)
                    .background(
                        Theme.Colors.tint,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                    )
                    .accessibilityHidden(true)
            }
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    labelText
                    valueText
                }
            } else {
                labelText
                Spacer()
                valueText
                    .multilineTextAlignment(.trailing)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    private var labelText: some View {
        Text(label)
            .textStyle(.body)
            .foregroundStyle(Theme.Colors.inkMuted)
    }

    private var valueText: some View {
        Text(value)
            .textStyle(.bodyStrong)
            .foregroundStyle(Theme.Colors.ink)
    }
}

#Preview {
    LightAndDarkPreview {
        FactRow(label: "Neighborhood", value: "Roosevelt Island", systemImage: "mappin")
        FactRow(label: "Location", value: "Cornell Tech, Roosevelt Island", systemImage: "mappin")
        FactRow(label: "Status", value: "Open")
    }
}
