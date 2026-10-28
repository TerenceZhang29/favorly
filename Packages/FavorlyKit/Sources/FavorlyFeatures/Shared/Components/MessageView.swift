import SwiftUI

/// An empty or error state: a symbol, a message and, when `onRetry` is given, a button (Retry unless named).
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
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(Theme.Colors.neutral)
                .accessibilityHidden(true)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier(messageIdentifier)
            if let onRetry {
                Button(actionTitle, action: onRetry)
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier(retryIdentifier)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.section)
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
