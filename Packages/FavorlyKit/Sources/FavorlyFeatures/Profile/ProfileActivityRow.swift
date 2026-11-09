import FavorlyCore
import SwiftUI

/// A completed request on a profile: "Helped" or "Asked", its title, and the location label only.
struct ProfileActivityRow: View {
    let request: HelpRequest
    let role: ProfileActivity.Role
    /// The points earned, such as "+18", for a favor the user helped with.
    var pointsText: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// "Helped" or "Asked".
    private var roleTitle: String { role.title }

    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.small))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.large))
    }

    var body: some View {
        // The role badge on the left, then the title and where it was, as in the mockup. At accessibility text
        // sizes the badge goes above, so the title keeps the row's width.
        layout { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Theme.Spacing.small)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(spokenLabel)
    }

    @ViewBuilder
    private var content: some View {
        TagBadge(text: roleTitle, colors: isHelped ? .tint : .quiet)
            .frame(minWidth: Theme.IconSize.roleBadge, alignment: .leading)
        VStack(alignment: .leading, spacing: Theme.Spacing.small / 2) {
            Text(request.title)
                .textStyle(.bodyStrong)
                .foregroundStyle(Theme.Colors.ink)
            Text(request.location.label)
                .textStyle(.meta)
                .foregroundStyle(Theme.Colors.inkMuted)
        }
        if let pointsText {
            Spacer(minLength: Theme.Spacing.medium)
            Text(pointsText)
                .textStyle(.metaStrong)
                .foregroundStyle(Theme.Colors.points)
        }
    }

    /// "Helped" gets the olive tint, "Asked" the quiet fill.
    private var isHelped: Bool { role == .helped }

    /// "Need a pinch of saffron, Ingredient, Helped, Downtown Brooklyn".
    private var spokenLabel: String {
        let parts = [request.title, roleTitle, request.location.label]
        return (pointsText.map { parts + ["\($0) points"] } ?? parts).joined(separator: ", ")
    }
}

#Preview {
    LightAndDarkPreview {
        ProfileActivityRow(
            request: HelpRequest(
                id: RequestID(rawValue: UUID()),
                title: "Need a pinch of saffron",
                details: "",
                location: TaggedLocation(
                    point: GeoPoint(latitude: 40.6929, longitude: -73.9857),
                    label: "Downtown Brooklyn"
                ),
                requesterID: UserID(rawValue: "preview-dana"),
                helperID: UserID(rawValue: "preview-bea"),
                status: .completed,
                createdAt: Date()
            ),
            role: .helped
        )
    }
}
