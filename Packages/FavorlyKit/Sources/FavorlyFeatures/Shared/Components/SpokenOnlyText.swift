import SwiftUI

/// Text that VoiceOver reads but the screen doesn't show, for information the design leaves out visually
/// but a screen-reader user still needs, such as how many requests are nearby. It takes no space.
struct SpokenOnlyText: View {
    let text: String
    /// Identifier for the element, so UI tests can read it.
    let identifier: String

    var body: some View {
        Color.clear
            .frame(height: 0)
            .accessibilityElement()
            .accessibilityLabel(text)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityIdentifier(identifier)
    }
}
