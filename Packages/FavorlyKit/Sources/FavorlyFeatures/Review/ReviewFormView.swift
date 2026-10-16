import FavorlyCore
import SwiftUI

/// The sheet where the requester rates the helper and leaves a comment.
struct ReviewFormView: View {
    @State private var viewModel: ReviewFormViewModel
    @Environment(\.dismiss) private var dismiss
    private let helperName: String
    private let onSubmitted: (Review) -> Void

    init(
        requestID: RequestID,
        helperName: String,
        environment: AppEnvironment,
        onSubmitted: @escaping (Review) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: ReviewFormViewModel(requestID: requestID, environment: environment))
        self.helperName = helperName
        self.onSubmitted = onSubmitted
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    StarRatingPicker(rating: $viewModel.rating)
                        .padding(.vertical, Theme.Spacing.medium)
                } header: {
                    SectionHeader(text: "How did \(helperName) do?")
                }

                Section {
                    TextField("Comment (optional)", text: $viewModel.comment, axis: .vertical)
                        .lineLimit(3 ... 6)
                        .doneKey(text: $viewModel.comment)
                        .accessibilityIdentifier("review.comment")
                    if let commentMessage = viewModel.commentMessage {
                        InlineMessage(text: commentMessage, identifier: "review.commentMessage")
                    }
                } footer: {
                    Text(viewModel.commentCountText)
                        .accessibilityIdentifier("review.count")
                }

                if let submitError = viewModel.submitError {
                    Section {
                        InlineMessage(text: submitError, identifier: "review.submitError")
                    }
                    .compactSectionSpacing()
                }

                Section {
                    Button("Submit") {
                        Task {
                            if let review = await viewModel.submit() {
                                onSubmitted(review)
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!viewModel.canSubmit)
                    .accessibilityIdentifier("review.submit")
                    .plainListRow()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Leave a review")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("review.cancel")
                }
            }
        }
    }
}

#Preview {
    ReviewFormView(requestID: RequestID(rawValue: UUID()), helperName: "Bea", environment: .preview())
}
