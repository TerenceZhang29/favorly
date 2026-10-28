import FavorlyCore
import SwiftUI

/// The "…" menu on someone else's request or profile, with its report sheet and block confirmation. A
/// successful block closes the screen, since its content is hidden from now on.
struct SafetyActions: ViewModifier {
    let isEnabled: Bool
    let reportTitle: String
    let personName: String
    /// Prefix for the identifiers, such as "detail" or "profile".
    let identifier: String
    let reportTarget: ReportTarget
    let environment: AppEnvironment
    /// Blocks the person; returns true when done.
    let block: () async -> Bool

    @State private var isReporting = false
    @State private var isConfirmingBlock = false
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .toolbar {
                if isEnabled {
                    ToolbarItem(placement: .primaryAction) {
                        SafetyMenu(
                            reportTitle: reportTitle,
                            personName: personName,
                            identifier: identifier,
                            onReport: { isReporting = true },
                            onBlock: { isConfirmingBlock = true }
                        )
                    }
                }
            }
            .sheet(isPresented: $isReporting) {
                ReportView(target: reportTarget, environment: environment)
            }
            .confirmationDialog("Block \(personName)?", isPresented: $isConfirmingBlock, titleVisibility: .visible) {
                Button("Block", role: .destructive) {
                    Task {
                        if await block() {
                            dismiss()
                        }
                    }
                }
                .accessibilityIdentifier("\(identifier).confirmBlock")
            } message: {
                Text(BlockCopy.explanation)
            }
    }
}
