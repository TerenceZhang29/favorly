import SwiftUI

/// An empty or error state: a symbol on a soft tile, a message and, when `onRetry` is given, a button
/// (Retry unless named).
struct MessageView: View {
    let systemImage: String
    let message: String
    /// Identifier for the message text, so UI tests can read it.
    let messageIdentifier: String
    var retryIdentifier = ""
    var actionTitle = "Retry"
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            CategoryIcon(systemImage: systemImage, isLarge: true)
            Text(message)
                .textStyle(.body)
                .foregroundStyle(Theme.Colors.inkMuted)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier(messageIdentifier)
            if let onRetry {
                Button(actionTitle, action: onRetry)
                    .buttonStyle(SecondaryButtonStyle())
                    .fixedSize()
                    .accessibilityIdentifier(retryIdentifier)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.section)
        .padding(.horizontal, Theme.Spacing.screen)
    }
}

#Preview {
    LightAndDarkPreview {
        MessageView(systemImage: "tray", message: "No requests within 1 mi", messageIdentifier: "preview.empty")
        MessageView(
            systemImage: "wifi.exclamationmark",
            message: "Your location isn't available right now.",
            messageIdentifier: "preview.error",
            retryIdentifier: "preview.retry"
        ) {}
    }
}
