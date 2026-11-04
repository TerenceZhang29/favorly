import SwiftUI

/// A list row with a checkmark when selected, for single-choice lists built from buttons.
struct SelectableRow: View {
    let title: String
    var subtitle: String?
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .textStyle(.body)
                    .foregroundStyle(Theme.Colors.ink)
                if let subtitle {
                    Text(subtitle)
                        .textStyle(.meta)
                        .foregroundStyle(Theme.Colors.inkMuted)
                }
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.brand)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
