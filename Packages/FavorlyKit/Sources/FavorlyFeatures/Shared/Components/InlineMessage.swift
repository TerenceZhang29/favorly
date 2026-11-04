import SwiftUI

/// A short validation or error message in the danger color, with a small warning symbol.
struct InlineMessage: View {
    let text: String
    /// Identifier for the message text, so UI tests can read it.
    let identifier: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
            Text(text)
                .accessibilityIdentifier(identifier)
        }
        .textStyle(.meta)
        .foregroundStyle(Theme.Colors.danger)
    }
}

#Preview {
    LightAndDarkPreview {
        InlineMessage(text: "Title must be at least 3 characters.", identifier: "preview.message")
    }
}
