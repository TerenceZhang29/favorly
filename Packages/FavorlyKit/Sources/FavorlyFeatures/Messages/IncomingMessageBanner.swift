import FavorlyCore
import Foundation
import SwiftUI

/// The card that slides down over any screen when a message arrives: who sent it, the favor, the message, and
/// Reply (opens the chat) or Later (dismisses it). VoiceOver announces it as it appears.
struct IncomingMessageBanner: View {
    let message: IncomingMessage
    let onReply: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            HStack(alignment: .top, spacing: Theme.Spacing.large) {
                Text(message.senderName.first.map { String($0).uppercased() } ?? "?")
                    .textStyle(.headline)
                    .foregroundStyle(Theme.Colors.onLime)
                    .frame(width: Theme.IconSize.bannerAvatar, height: Theme.IconSize.bannerAvatar)
                    .background(Theme.Colors.lime, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Theme.Spacing.small / 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(message.senderName)
                            .textStyle(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("now")
                            .textStyle(.meta)
                            .foregroundStyle(Theme.Colors.bannerMuted)
                    }
                    Text(message.favorTitle)
                        .textStyle(.metaStrong)
                        .foregroundStyle(Theme.Colors.bannerAccent)
                        .lineLimit(1)
                    Text(message.text)
                        .textStyle(.body)
                        .lineLimit(3)
                        .padding(.top, Theme.Spacing.small)
                        .accessibilityIdentifier("banner.text")
                }
                .foregroundStyle(Theme.Colors.onBanner)
            }
            .accessibilityElement(children: .combine)

            HStack(spacing: Theme.Spacing.medium) {
                Button(action: onReply) {
                    Label("Reply", systemImage: "bubble.left")
                        .textStyle(.button)
                        .foregroundStyle(Theme.Colors.onBannerButton)
                        .frame(maxWidth: .infinity, minHeight: Theme.pillHeight + Theme.Spacing.small)
                        .background(
                            Theme.Colors.bannerButton,
                            in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                        )
                }
                .accessibilityLabel("Reply to \(message.senderName)")
                .accessibilityIdentifier("banner.reply")
                Button(action: onLater) {
                    Text("Later")
                        .textStyle(.button)
                        .foregroundStyle(Theme.Colors.onBanner)
                        .frame(maxWidth: .infinity, minHeight: Theme.pillHeight + Theme.Spacing.small)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                                .strokeBorder(Theme.Colors.bannerOutline, lineWidth: Theme.borderWidth)
                        )
                }
                .accessibilityIdentifier("banner.later")
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.large + Theme.Spacing.small / 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.banner, style: .continuous)
                .fill(Theme.Colors.banner)
                .groveShadow(Theme.Shadow.banner)
        )
        .padding(.horizontal, Theme.Spacing.large)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("banner")
        .onAppear {
            AccessibilityNotification.Announcement(message.announcement).post()
        }
    }
}

#Preview {
    LightAndDarkPreview {
        IncomingMessageBanner(
            message: IncomingMessage(
                messageID: MessageID(rawValue: UUID()),
                requestID: RequestID(rawValue: UUID()),
                senderName: "Maya",
                favorTitle: "Dresser up 3 flights",
                text: "Perfect, I'll meet you on the front steps at 6"
            ),
            onReply: {},
            onLater: {}
        )
    }
}
