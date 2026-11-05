import SwiftUI

/// An error message with a warning symbol, in the danger color on its soft tint.
struct ErrorBanner: View {
    let message: String
    /// Identifier for the message text, so UI tests can read it.
    let identifier: String

    var body: some View {
        Label {
            Text(message)
                .accessibilityIdentifier(identifier)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
        }
        .textStyle(.bodyStrong)
        .foregroundStyle(Theme.Colors.danger)
        .padding(Theme.Spacing.xLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.dangerTint, in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
    }
}

#Preview {
    LightAndDarkPreview {
        ErrorBanner(message: "Someone else already claimed this.", identifier: "preview.error")
    }
}
