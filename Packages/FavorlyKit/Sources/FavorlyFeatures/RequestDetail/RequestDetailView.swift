import FavorlyCore
import SwiftUI

struct RequestDetailView: View {
    private let environment: AppEnvironment
    @State private var viewModel: RequestDetailViewModel
    @State private var isConfirmingPickUp = false
    @State private var isShowingChat = false
    @State private var isReviewing = false

    init(requestID: RequestID, environment: AppEnvironment) {
        self.environment = environment
        _viewModel = State(initialValue: RequestDetailViewModel(requestID: requestID, environment: environment))
    }

    var body: some View {
        List {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.section)
                    .plainListRow()
                    .accessibilityIdentifier("detail.loading")
            case let .loaded(request):
                summary(of: request)
                facts(of: request)
                if let review = viewModel.review {
                    reviewSection(review)
                }
                actions
            case let .failed(message):
                MessageView(
                    systemImage: "exclamationmark.triangle",
                    message: message,
                    messageIdentifier: "detail.loadError",
                    retryIdentifier: "detail.retry"
                ) {
                    Task { await viewModel.load() }
                }
                .plainListRow()
            }
        }
        .navigationTitle("Request")
        .toolbarTitleDisplayMode(.inline)
        .modifier(SafetyActions(
            isEnabled: viewModel.canReportOrBlock,
            reportTitle: "Report request",
            personName: viewModel.requesterName,
            identifier: "detail",
            reportTarget: .request(viewModel.requestID),
            environment: environment,
            block: viewModel.blockRequester
        ))
        .confirmationDialog("Pick up this request?", isPresented: $isConfirmingPickUp, titleVisibility: .visible) {
            Button("Confirm pick up") {
                Task { await viewModel.pickUp() }
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("The requester will see that you picked it up.")
        }
        .navigationDestination(isPresented: $isShowingChat) {
            ChatView(requestID: viewModel.requestID, environment: environment)
        }
        .sheet(isPresented: $isReviewing) {
            ReviewFormView(
                requestID: viewModel.requestID,
                helperName: viewModel.helperName ?? "",
                environment: environment
            ) { _ in
                Task { await viewModel.load() }
            }
        }
        .task {
            await viewModel.load()
            await viewModel.observeChanges()
        }
    }

    private func summary(of request: HelpRequest) -> some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                CategoryIcon(
                    systemImage: request.category.systemImage,
                    color: request.category.color,
                    isLarge: true
                )
                Text(request.title)
                    .font(.title2.bold())
                    .accessibilityIdentifier("detail.title")
                // The Status row below is what VoiceOver and the UI tests read.
                StatusBadge(text: viewModel.statusText, color: request.status.color)
                    .accessibilityHidden(true)
                if !request.details.isEmpty {
                    Text(request.details)
                        .lineSpacing(Theme.Spacing.small)
                        .accessibilityIdentifier("detail.details")
                }
            }
            .padding(.vertical, Theme.Spacing.medium)
        }
    }

    private func facts(of request: HelpRequest) -> some View {
        Section {
            fact("Category", request.category.title, id: "category", systemImage: "tag")
            fact("Location", request.location.label, id: "location", systemImage: "mappin")
            if let distanceText = viewModel.distanceText {
                fact("Distance", distanceText, id: "distance", systemImage: "ruler")
            }
            person(
                "Posted by",
                viewModel.isOwn ? "\(viewModel.requesterName) (you)" : viewModel.requesterName,
                id: "requester",
                systemImage: "person",
                user: (request.requesterID, viewModel.requesterScore)
            )
            fact("Status", viewModel.statusText, id: "status", systemImage: "checkmark.seal")
            if let helperID = request.helperID, let helperName = viewModel.helperName {
                person(
                    "Helper",
                    helperName,
                    id: "helper",
                    systemImage: "hands.sparkles",
                    user: (helperID, viewModel.helperScore)
                )
            }
        }
    }

    /// Each action is its own section, so each full-width button gets the same corners as the cards above.
    private var actions: some View {
        Group {
            if let actionError = viewModel.actionError {
                Section {
                    ErrorBanner(message: actionError, identifier: "detail.error")
                        .plainListRow()
                }
                .compactSectionSpacing()
            }
            if viewModel.canMessage {
                Section {
                    Button {
                        isShowingChat = true
                    } label: {
                        Label(viewModel.messageButtonTitle, systemImage: "bubble.left.and.bubble.right")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("detail.message")
                    .plainListRow()
                }
                .compactSectionSpacing()
            }
            if viewModel.canReview {
                Section {
                    Button {
                        isReviewing = true
                    } label: {
                        Label("Leave a review", systemImage: "star")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("detail.review")
                    .plainListRow()
                }
                .compactSectionSpacing()
            }
            if viewModel.canPickUp {
                Section {
                    Button("Pick up") { isConfirmingPickUp = true }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("detail.pickUp")
                        .plainListRow()
                }
                .compactSectionSpacing()
            }
            if viewModel.canComplete {
                Section {
                    Button("Mark completed") {
                        Task { await viewModel.complete() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("detail.complete")
                    .plainListRow()
                }
                .compactSectionSpacing()
            }
            if let autoCompleteNote = viewModel.autoCompleteNote {
                Section {
                    Label(autoCompleteNote, systemImage: "clock")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .plainListRow()
                        .accessibilityIdentifier("detail.autoCompleteNote")
                }
                .compactSectionSpacing()
            }
            if viewModel.canCancel {
                Section {
                    Button("Cancel request", role: .destructive) {
                        Task { await viewModel.cancel() }
                    }
                    .buttonStyle(SecondaryButtonStyle(color: Theme.Colors.statusCancelled))
                    .accessibilityIdentifier("detail.cancel")
                    .plainListRow()
                }
                .compactSectionSpacing()
            }
        }
        .disabled(viewModel.isWorking)
    }

    /// The requester's review of the helper, shown once it exists.
    private func reviewSection(_ review: Review) -> some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                StarRating(rating: review.rating)
                if !review.comment.isEmpty {
                    Text(review.comment)
                }
            }
            .padding(.vertical, Theme.Spacing.small)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(viewModel.reviewTitle)
            .accessibilityValue(
                review.comment.isEmpty
                    ? "\(review.rating) out of \(ReviewRules.ratingRange.upperBound) stars"
                    : "\(review.rating) out of \(ReviewRules.ratingRange.upperBound) stars: \(review.comment)"
            )
            .accessibilityIdentifier("detail.reviewSummary")
        } header: {
            SectionHeader(text: viewModel.reviewTitle)
        }
    }

    /// A requester or helper row with their Kindness score. Tapping it opens their profile.
    /// VoiceOver and the UI tests read the name as the value, as before; the score is in the hint.
    private func person(
        _ label: String,
        _ name: String,
        id: String,
        systemImage: String,
        user: (id: UserID, score: Int?)
    ) -> some View {
        let score = user.score
        return NavigationLink(value: user.id) {
            HStack(spacing: Theme.Spacing.medium) {
                FactRow(label: label, value: name, systemImage: systemImage)
                if let score {
                    ScoreLabel(points: score)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(name)
        .accessibilityHint(score.map { "Kindness score \($0). Opens their profile." } ?? "Opens their profile.")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("detail.\(id)")
    }

    private func fact(_ label: String, _ value: String, id: String, systemImage: String) -> some View {
        FactRow(label: label, value: value, systemImage: systemImage)
            .accessibilityIdentifier("detail.\(id)")
    }
}
