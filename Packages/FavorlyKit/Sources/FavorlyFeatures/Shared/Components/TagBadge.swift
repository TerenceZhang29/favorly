import SwiftUI

/// A badge for short tags: "Yours" on lime, "New" in the warm spark color, "Helped" on the tint.
struct TagBadge: View {
    let text: String
    var colors: BadgeColors = .lime

    var body: some View {
        StatusBadge(text: text, colors: colors)
    }
}

#Preview {
    LightAndDarkPreview {
        TagBadge(text: "Yours")
        TagBadge(text: "New", colors: .spark)
        TagBadge(text: "Helped", colors: .tint)
    }
}
