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
            headerLayout {
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
                if !stacksBadge {
                    badge
                }
            }
            Text(item.request.title)
                .textStyle(.cardTitle)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if stacksBadge {
                badge
            }
            // Where to meet and the mockup's "I can help" pill. The whole card opens the request.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Spacing.large) {
                    place
                    Spacer(minLength: 0)
                    helpPill
                }
                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    place
                    helpPill
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
    }

    /// At accessibility text sizes the badge goes under the title, so the text keeps the row's width.
    private var stacksBadge: Bool { dynamicTypeSize.isAccessibilitySize }

    /// The category tile beside its text, or above it at accessibility text sizes so words don't break.
    private var headerLayout: AnyLayout {
        stacksBadge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.medium))
            : AnyLayout(HStackLayout(spacing: Theme.Spacing.medium + Theme.Spacing.small / 2))
    }

    /// The meeting spot, or the neighborhood when there is none.
    private var place: some View {
        Label(
            item.request.meetingSpot.isEmpty ? item.request.location.label : item.request.meetingSpot,
            systemImage: item.request.meetingSpot.isEmpty ? "mappin" : "figure.wave"
        )
        .textStyle(.meta)
        .foregroundStyle(Theme.Colors.inkMuted)
        .lineLimit(2)
    }

    /// Not a separate button: it shows what tapping the card is for. Hidden on the user's own requests.
    @ViewBuilder
    private var helpPill: some View {
        if !isOwn {
            Text("I can help")
                .textStyle(.metaStrong)
                .foregroundStyle(Theme.Colors.onTint)
                .padding(.horizontal, Theme.Spacing.xLarge)
                .frame(minHeight: Theme.pillHeight)
                .background(Theme.Colors.tint, in: Capsule())
        }
    }

    /// "Yours" on the user's own requests, otherwise the status ("Open").
    @ViewBuilder
    private var badge: some View {
        if isOwn {
            TagBadge(text: "Yours")
        } else {
            StatusBadge(text: item.request.status.title, colors: item.request.status.badgeColors)
        }
    }

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
