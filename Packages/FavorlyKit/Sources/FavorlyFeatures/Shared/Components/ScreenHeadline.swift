import SwiftUI

/// The mockup's headline at the top of a tab, such as "Neighbors who could use a hand", with an optional
/// accent at the end in the brand color. It replaces the system navigation title on the tabs' first screens.
struct ScreenHeadline: View {
    let text: String
    var accent: String?

    var body: some View {
        headline
            .textStyle(.largeTitle)
            .foregroundStyle(Theme.Colors.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    private var headline: Text {
        guard let accent else { return Text(text) }
        return Text(text) + Text(accent).foregroundStyle(Theme.Colors.brand)
    }
}

#Preview {
    LightAndDarkPreview {
        ScreenHeadline(text: "Neighbors who could use ", accent: "a hand")
        ScreenHeadline(text: "My Activity")
    }
}
