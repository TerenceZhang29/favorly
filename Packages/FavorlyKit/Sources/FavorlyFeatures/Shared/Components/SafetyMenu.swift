import SwiftUI

/// The "…" toolbar menu on someone else's request or profile: report, and block the person.
struct SafetyMenu: View {
    let reportTitle: String
    let personName: String
    /// Prefix for the identifiers, such as "detail" or "profile".
    let identifier: String
    let onReport: () -> Void
    let onBlock: () -> Void

    var body: some View {
        Menu {
            Button(reportTitle, systemImage: "exclamationmark.bubble", action: onReport)
                .accessibilityIdentifier("\(identifier).report")
            Button("Block \(personName)", systemImage: "hand.raised", role: .destructive, action: onBlock)
                .accessibilityIdentifier("\(identifier).block")
        } label: {
            Label("More", systemImage: "ellipsis.circle")
        }
        .accessibilityIdentifier("\(identifier).more")
    }
}
