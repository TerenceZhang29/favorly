import FavorlyCore
import SwiftUI

/// One conversation on the Messages tab: the other person, the time, the favor with the user's role, and the
/// last message with an unread count. Unread threads show the message and time in bold.
struct InboxRow: View {
    let thread: InboxThread
    let timeText: String

    private var isUnread: Bool { thread.unreadCount > 0 }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.large) {
            AvatarView(name: thread.otherName, side: Theme.IconSize.inboxAvatar)
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.medium) {
                    Text(thread.otherName)
                        .textStyle(.headline)
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(timeText)
                        .textStyle(isUnread ? .metaStrong : .meta)
                        .foregroundStyle(isUnread ? Theme.Colors.points : Theme.Colors.inkMuted)
                }
                Text("\(thread.roleText) · \(thread.favorTitle)")
                    .textStyle(.metaStrong)
                    .foregroundStyle(Theme.Colors.points)
                    .lineLimit(1)
                HStack(spacing: Theme.Spacing.medium) {
                    Text(thread.previewText)
                        .textStyle(isUnread ? .bodyStrong : .body)
                        .foregroundStyle(isUnread ? Theme.Colors.ink : Theme.Colors.inkMuted)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if isUnread {
                        Text(String(thread.unreadCount))
                            .textStyle(.metaStrong)
                            .foregroundStyle(Theme.Colors.onBrand)
                            .padding(.horizontal, Theme.Spacing.small + Theme.Spacing.small / 2)
                            .frame(minWidth: Theme.IconSize.rowBadge, minHeight: Theme.IconSize.rowBadge)
                            .background(Theme.Colors.brand, in: Capsule())
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// "Bea, Your request, Need a cup of rice. On my way. 5:20 PM. 2 unread."
    private var accessibilityText: String {
        [
            "\(thread.otherName), \(thread.roleText), \(thread.favorTitle).",
            "\(thread.previewText).",
            "\(timeText).",
            thread.unreadLabel.map { "\($0)." },
        ]
        .compactMap(\.self)
        .joined(separator: " ")
    }
}
