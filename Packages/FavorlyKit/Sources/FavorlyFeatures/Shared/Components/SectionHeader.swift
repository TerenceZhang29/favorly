import SwiftUI

/// A list section header in sentence case and the Grove headline style.
struct SectionHeader: View {
    let text: String

    var body: some View {
        Text(text)
            .textStyle(.headline)
            .foregroundStyle(Theme.Colors.ink)
            .textCase(nil)
    }
}

#Preview {
    LightAndDarkPreview {
        SectionHeader(text: "What do you need?")
        SectionHeader(text: "7 requests")
    }
}
