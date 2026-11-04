import FavorlyCore
import SwiftUI

/// A request on Nearby, drawn as a card: the category, the distance · name · time line, the title, and
/// "Yours" for the user's own requests.
struct RequestRow: View {
    let item: NearbyRequest
    let requesterName: String
    let isOwn: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium + Theme.Spacing.small / 2) {
            HStack(spacing: Theme.Spacing.medium + Theme.Spacing.small / 2) {
                CategoryIcon(systemImage: item.request.category.systemImage)
                VStack(alignment: .leading, spacing: Theme.Spacing.small / 2) {
                    Text(item.request.category.title)
                        .textStyle(.metaStrong)
                        .foregroundStyle(Theme.Colors.ink)
                    Text("\(distanceText) · \(requesterName) · \(postedText)")
                        .textStyle(.meta)
                        .foregroundStyle(Theme.Colors.inkMuted)
                }
                Spacer(minLength: Theme.Spacing.medium)
                if isOwn, !stacksBadge {
                    ownBadge
                }
            }
            Text(item.request.title)
                .textStyle(.cardTitle)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if isOwn, stacksBadge {
                ownBadge
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
    }

    /// At accessibility text sizes the badge goes under the title, so the text keeps the row's width.
    private var stacksBadge: Bool { dynamicTypeSize.isAccessibilitySize }

    private var ownBadge: some View { TagBadge(text: "Yours") }

    private var distanceText: Text {
        Text(DistanceFormatter.miles(item.distanceMeters))
            .foregroundStyle(Theme.Colors.points)
    }

    private var postedText: String {
        item.request.createdAt.formatted(.relative(presentation: .named))
    }

    private var spokenLabel: String {
        let distance = DistanceFormatter.spokenMiles(item.distanceMeters)
        let parts = [
            item.request.title,
            item.request.category.title,
            "\(distance) away",
            "posted \(postedText) by \(requesterName)",
        ]
        return (isOwn ? parts + ["yours"] : parts).joined(separator: ", ")
    }
}
