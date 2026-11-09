import FavorlyCore
import SwiftUI

struct RequestDetailView: View {
    private let environment: AppEnvironment
    @State private var viewModel: RequestDetailViewModel
    @State private var isConfirmingClaim = false
    @State private var isShowingChat = false
    @State private var isReviewing = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
                people(of: request)
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
        .groveListBackground()
        .navigationTitle("Request")
        .toolbarTitleDisplayMode(.inline)
        // The title stays for VoiceOver, but the bar shows none, and "‹ Nearby" replaces the back button.
        .hidingNavigationTitle()
        .groveBackLink()
        .modifier(SafetyActions(
            isEnabled: viewModel.canReportOrBlock,
            reportTitle: "Report request",
            personName: viewModel.requesterName,
            identifier: "detail",
            reportTarget: .request(viewModel.requestID),
            environment: environment,
            block: viewModel.blockRequester
        ))
        .sheet(isPresented: $isConfirmingClaim) {
            if case let .loaded(request) = viewModel.state {
                ClaimConfirmationView(
                    title: request.title,
                    requesterName: viewModel.requesterName,
                    detailLine: [
                        viewModel.distanceText,
                        request.meetingSpot.isEmpty ? request.location.label : request.meetingSpot,
                    ]
                    .compactMap(\.self)
                    .joined(separator: " · ")
                ) {
                    Task { await viewModel.pickUp() }
                }
            }
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
                // The badge and time on one line, or the time under the badge when it is long.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Spacing.medium + Theme.Spacing.small / 2) {
                        statusBadge(of: request)
                        timeLine(of: request)
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                        statusBadge(of: request)
                        timeLine(of: request)
                    }
                }
                Text(request.title)
                    .textStyle(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityIdentifier("detail.title")
                if !request.details.isEmpty {
                    Text(request.details)
                        .textStyle(.body)
                        .foregroundStyle(Theme.Colors.inkMuted)
                        .lineSpacing(Theme.Spacing.small)
                        .accessibilityIdentifier("detail.details")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.screen + Theme.Spacing.small)
            .padding(.vertical, Theme.Spacing.small)
            .plainListRow()
        }
    }

    private func facts(of request: HelpRequest) -> some View {
        Section {
            fact("Neighborhood", request.location.label, id: "location", systemImage: "mappin")
            if !request.meetingSpot.isEmpty {
                fact("Meeting spot", request.meetingSpot, id: "meetingSpot", systemImage: "figure.wave")
            }
            fact("Posted", postedText(of: request), id: "posted", systemImage: "clock")
        }
        .groveRows()
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
                    VStack(spacing: Theme.Spacing.medium) {
                        Button("I can help") { isConfirmingClaim = true }
                            .buttonStyle(PrimaryButtonStyle())
                            .accessibilityIdentifier("detail.pickUp")
                        Text("\(viewModel.requesterName) will see that you claimed it.")
                            .textStyle(.meta)
                            .foregroundStyle(Theme.Colors.inkMuted)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("detail.claimNote")
                    }
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
                        .textStyle(.meta)
                        .foregroundStyle(Theme.Colors.inkMuted)
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
                    .buttonStyle(SecondaryButtonStyle(isDanger: true))
                    .accessibilityIdentifier("detail.cancel")
                    .plainListRow()
                }
                .compactSectionSpacing()
            }
        }
        .disabled(viewModel.isWorking)
    }
}

private extension RequestDetailView {
    /// A requester or helper card: their avatar, "Posted by" over their name, and their Kindness score.
    /// Tapping it opens their profile. VoiceOver and the UI tests read the name as the value, as before; the
    /// score is in the hint.
    func person(
        _ label: String,
        _ name: String,
        id: String,
        user: (id: UserID, score: Int?)
    ) -> some View {
        let score = user.score
        return NavigationLink(value: user.id) {
            HStack(spacing: Theme.Spacing.large) {
                AvatarView(name: name, side: Theme.IconSize.row)
                // At accessibility text sizes the score goes under the name, so the name keeps the row's width.
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.small))
                    : AnyLayout(HStackLayout(spacing: Theme.Spacing.medium))
                layout {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small / 2) {
                        Text(label)
                            .textStyle(.meta)
                            .foregroundStyle(Theme.Colors.inkMuted)
                        Text(name)
                            .textStyle(.headline)
                            .foregroundStyle(Theme.Colors.ink)
                    }
                    if !dynamicTypeSize.isAccessibilitySize {
                        Spacer(minLength: Theme.Spacing.medium)
                    }
                    if let score {
                        ScoreLabel(points: score)
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.small)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(name)
        .accessibilityHint(score.map { "Kindness score \($0). Opens their profile." } ?? "Opens their profile.")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("detail.\(id)")
    }

    /// The requester, and the helper once there is one, each as its own card that opens their profile.
    @ViewBuilder
    func people(of request: HelpRequest) -> some View {
        Section {
            person(
                "Posted by",
                viewModel.isOwn ? "\(viewModel.requesterName) (you)" : viewModel.requesterName,
                id: "requester",
                user: (request.requesterID, viewModel.requesterScore)
            )
        }
        .groveRows()
        .compactSectionSpacing()
        if let helperID = request.helperID, let helperName = viewModel.helperName {
            Section {
                person("Helper", helperName, id: "helper", user: (helperID, viewModel.helperScore))
            }
            .groveRows()
            .compactSectionSpacing()
        }
    }

    /// The status badge and "0.1 mi away · 22 minutes ago". The badge is what VoiceOver and the UI tests
    /// read as the status ("Status, Claimed by Bea").
    func statusBadge(of request: HelpRequest) -> some View {
        StatusBadge(text: viewModel.statusText, colors: request.status.badgeColors)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Status")
            .accessibilityValue(viewModel.statusText)
            .accessibilityIdentifier("detail.status")
    }

    func timeLine(of request: HelpRequest) -> some View {
        Text([viewModel.distanceText.map { "\($0) away" }, postedText(of: request)].compactMap(\.self)
            .joined(separator: " · "))
            .textStyle(.meta)
            .foregroundStyle(Theme.Colors.inkMuted)
            .accessibilityIdentifier("detail.distance")
    }

    func postedText(of request: HelpRequest) -> String {
        request.createdAt.formatted(.relative(presentation: .named))
    }

    /// The requester's review of the helper, shown once it exists.
    func reviewSection(_ review: Review) -> some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                StarRating(rating: review.rating)
                if !review.comment.isEmpty {
                    Text(review.comment)
                        .textStyle(.body)
                        .foregroundStyle(Theme.Colors.ink)
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
        .groveRows()
    }

    func fact(_ label: String, _ value: String, id: String, systemImage: String) -> some View {
        FactRow(label: label, value: value, systemImage: systemImage)
            .accessibilityIdentifier("detail.\(id)")
    }
}
