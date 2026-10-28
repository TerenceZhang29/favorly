import FavorlyCore
import SwiftUI

/// The sheet for reporting something. After sending it thanks the user and offers Done.
struct ReportView: View {
    @State private var viewModel: ReportViewModel
    @Environment(\.dismiss) private var dismiss

    init(target: ReportTarget, environment: AppEnvironment) {
        _viewModel = State(initialValue: ReportViewModel(target: target, environment: environment))
    }

    var body: some View {
        NavigationStack {
            Form {
                if viewModel.didSend {
                    Section {
                        MessageView(
                            systemImage: "checkmark.shield",
                            message: "Thanks for telling us. We review every report, usually within a day.",
                            messageIdentifier: "report.sent"
                        )
                        .plainListRow()
                    }
                } else {
                    reasons
                    Section {
                        TextField("What happened? (optional)", text: $viewModel.note, axis: .vertical)
                            .lineLimit(3 ... 6)
                            .doneKey(text: $viewModel.note)
                            .accessibilityIdentifier("report.note")
                    } footer: {
                        Text("The person you report is not told who reported them.")
                    }
                    if let sendError = viewModel.sendError {
                        Section {
                            InlineMessage(text: sendError, identifier: "report.error")
                        }
                        .compactSectionSpacing()
                    }
                    Section {
                        Button("Send report") {
                            Task { await viewModel.send() }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!viewModel.canSend)
                        .accessibilityIdentifier("report.send")
                        .plainListRow()
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(viewModel.title)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: viewModel.didSend ? .confirmationAction : .cancellationAction) {
                    Button(viewModel.didSend ? "Done" : "Cancel") { dismiss() }
                        .accessibilityIdentifier(viewModel.didSend ? "report.done" : "report.cancel")
                }
            }
        }
    }

    private var reasons: some View {
        Section {
            ForEach(ReportReason.allCases, id: \.self) { reason in
                Button {
                    viewModel.reason = reason
                } label: {
                    SelectableRow(title: reason.title, isSelected: viewModel.reason == reason)
                }
                .accessibilityIdentifier("report.reason.\(reason.rawValue)")
            }
        } header: {
            SectionHeader(text: "What's wrong?")
        }
    }
}

#Preview {
    ReportView(target: .user(UserID(rawValue: "preview-bea")), environment: .preview())
}
