import SwiftUI

/// One chat message: the signed-in user's on the right in ink, the other person's on the left on a card.
struct MessageBubble: View {
    let text: String
    /// "You" or the sender's name.
    let senderName: String
    /// "9:41 PM".
    let timeText: String
    let isMine: Bool

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: Theme.Spacing.small) {
            Text(text)
                .textStyle(.body)
                .foregroundStyle(isMine ? Theme.Colors.onBubbleMine : Theme.Colors.ink)
                .padding(.horizontal, Theme.Spacing.large + Theme.Spacing.small / 2)
                .padding(.vertical, Theme.Spacing.medium + Theme.Spacing.small / 2)
                .background(isMine ? Theme.Colors.bubbleMine : Theme.Colors.surface, in: shape)
                .overlay {
                    if !isMine {
                        shape.strokeBorder(Theme.Colors.surfaceBorder, lineWidth: Theme.borderWidth)
                    }
                }
            Text("\(senderName) · \(timeText)")
                .textStyle(.meta)
                .foregroundStyle(Theme.Colors.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
        .padding(.leading, isMine ? Theme.Spacing.bubbleInset : Theme.Spacing.xLarge)
        .padding(.trailing, isMine ? Theme.Spacing.xLarge : Theme.Spacing.bubbleInset)
        .padding(.vertical, Theme.Spacing.small)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(senderName) said: \(text), at \(timeText)")
    }

    /// Rounded on every corner but the one nearest the sender, which is tighter, like a speech tail.
    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: Theme.Radius.bubble,
            bottomLeadingRadius: isMine ? Theme.Radius.bubble : Theme.Radius.bubbleTail,
            bottomTrailingRadius: isMine ? Theme.Radius.bubbleTail : Theme.Radius.bubble,
            topTrailingRadius: Theme.Radius.bubble,
            style: .continuous
        )
    }
}

#Preview {
    LightAndDarkPreview {
        MessageBubble(text: "On my way", senderName: "Bea", timeText: "9:41 PM", isMine: false)
        MessageBubble(text: "Thank you! The door code is 1234.", senderName: "You", timeText: "9:42 PM", isMine: true)
    }
}
