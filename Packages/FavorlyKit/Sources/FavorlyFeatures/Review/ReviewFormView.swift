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
                    VStack(spacing: Theme.Spacing.large) {
                        AvatarView(name: helperName)
                        Text("How did \(helperName) do?")
                            .textStyle(.title)
                            .foregroundStyle(Theme.Colors.ink)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        StarRatingPicker(rating: $viewModel.rating)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.medium)
                    .plainListRow()
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
                        .textStyle(.meta)
                        .foregroundStyle(Theme.Colors.inkMuted)
                        .accessibilityIdentifier("review.count")
                }
                .groveRows()

                if let submitError = viewModel.submitError {
                    Section {
                        InlineMessage(text: submitError, identifier: "review.submitError")
                    }
                    .compactSectionSpacing()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .groveListBackground()
            .navigationTitle("Leave a review")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("review.cancel")
                }
                // Submit sits in the bar, as in the mockup, and is dimmed until a rating is chosen.
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            if let review = await viewModel.submit() {
                                onSubmitted(review)
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                    .accessibilityIdentifier("review.submit")
                }
            }
        }
    }
}

#Preview {
    ReviewFormView(requestID: RequestID(rawValue: UUID()), helperName: "Bea", environment: .preview())
}
