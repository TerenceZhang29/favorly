import FavorlyCore
import SwiftUI

struct ActivityView: View {
    /// The request that was just posted, shown highlighted.
    private let highlightedRequestID: RequestID?
    @State private var viewModel: ActivityViewModel
    /// The completed request being reviewed from its row, if any.
    @State private var reviewing: HelpRequest?
    /// The request whose chat the Message pill opened. A button, not a second link in the row: with two links
    /// in one list row, tapping the card could open the chat instead of the request.
    @State private var chatting: ChatDestination?
    private let environment: AppEnvironment

    init(environment: AppEnvironment, highlightedRequestID: RequestID?) {
        self.environment = environment
        self.highlightedRequestID = highlightedRequestID
        _viewModel = State(initialValue: ActivityViewModel(environment: environment))
    }

    var body: some View {
        List {
            Section {
                ScreenHeadline(text: "My Activity")
                    .padding(.horizontal, Theme.Spacing.screen)
                    .padding(.top, Theme.Spacing.section)
                    .plainListRow()
                Picker("Show", selection: $viewModel.segment) {
                    ForEach(ActivitySegment.allCases) { segment in
                        Text(segment.title).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("activity.segment")
                .listRowInsets(EdgeInsets(
                    top: Theme.Spacing.small,
                    leading: Theme.Spacing.screen,
                    bottom: Theme.Spacing.medium,
                    trailing: Theme.Spacing.screen
                ))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if let actionError = viewModel.actionError {
                Section {
                    ErrorBanner(message: actionError, identifier: "activity.error")
                        .padding(.horizontal, Theme.Spacing.screen)
                        .plainListRow()
                }
            }

            Section {
                results
            }
        }
        .listStyle(.plain)
        .groveListBackground()
        .navigationTitle("My Activity")
        .hidingNavigationBar()
        .navigationDestination(item: $chatting) { destination in
            ChatView(requestID: destination.requestID, environment: environment)
        }
        .sheet(item: $reviewing) { request in
            ReviewFormView(
                requestID: request.id,
                helperName: request.helperID.map { environment.session.displayName(for: $0) } ?? "",
                environment: environment
            ) { _ in
                Task { await viewModel.load() }
            }
        }
        .refreshable { await viewModel.load() }
        .task(id: viewModel.reloadKey) { await viewModel.load() }
        .task { await viewModel.observeChanges() }
        .onChange(of: highlightedRequestID, initial: true) { _, highlighted in
            if highlighted != nil {
                viewModel.segment = .posted
            }
        }
    }

    @ViewBuilder
    private var results: some View {
        if case let .failed(message) = viewModel.state {
            MessageView(
                systemImage: "exclamationmark.triangle",
                message: message,
                messageIdentifier: "activity.error",
                retryIdentifier: "activity.retry"
            ) {
                Task { await viewModel.load() }
            }
            .plainListRow()
        } else if let items = viewModel.items {
            if items.isEmpty {
                MessageView(
                    systemImage: viewModel.segment == .posted ? "square.and.pencil" : "hand.thumbsup",
                    message: viewModel.segment.emptyMessage,
                    messageIdentifier: "activity.empty"
                )
                .plainListRow()
            }
            ForEach(items) { request in
                let isNew = request.id == highlightedRequestID
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    NavigationLink(value: request.id) {
                        ActivityRow(request: request, subtitle: viewModel.subtitle(for: request), isNew: isNew)
                    }
                    .buttonStyle(.plain)
                    .navigationLinkIndicatorVisibility(.hidden)
                    .accessibilityIdentifier("activity.row.\(request.id.rawValue.uuidString)")
                    actions(for: request)
                }
                .cardRow(isHighlighted: isNew)
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.section)
                .plainListRow()
                .accessibilityIdentifier("activity.loading")
        }
    }
}

private extension ActivityView {
    /// The mockup's pills under a row: Message, Mark completed, Leave a review, or the points earned.
    @ViewBuilder
    func actions(for request: HelpRequest) -> some View {
        let message = viewModel.canMessage(request)
        let complete = viewModel.canComplete(request)
        let review = viewModel.canReview(request)
        let points = viewModel.earnedPointsText(for: request)
        if message || complete || review || points != nil {
            FlowLayout {
                if message {
                    pill("Message", symbol: "bubble.left", isPrimary: false, id: "message", request) {
                        chatting = ChatDestination(requestID: request.id)
                    }
                }
                if complete {
                    pill("Mark completed", isPrimary: true, id: "complete", request) {
                        Task { await viewModel.complete(request) }
                    }
                }
                if review {
                    pill("Leave a review", symbol: "star.fill", isPrimary: true, id: "review", request) {
                        reviewing = request
                    }
                }
                if let points {
                    Text(points)
                        .textStyle(.metaStrong)
                        .foregroundStyle(Theme.Colors.points)
                        .frame(minHeight: Theme.pillHeight)
                        .accessibilityLabel("\(points.replacingOccurrences(of: "pts", with: "points")) earned")
                        .accessibilityIdentifier("activity.points.\(request.id.rawValue.uuidString)")
                }
            }
            .padding(.leading, Theme.IconSize.row + Theme.Spacing.large)
        }
    }

    /// One action pill, identified as `activity.<id>.<request>`.
    func pill(
        _ title: String,
        symbol: String? = nil,
        isPrimary: Bool,
        id: String,
        _ request: HelpRequest,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.small) {
                if let symbol {
                    Image(systemName: symbol)
                        .accessibilityHidden(true)
                }
                Text(title)
            }
            .modifier(PillStyle(isPrimary: isPrimary))
        }
        .buttonStyle(.borderless)
        .accessibilityIdentifier("activity.\(id).\(request.id.rawValue.uuidString)")
    }
}

#Preview {
    NavigationStack {
        ActivityView(environment: .preview(), highlightedRequestID: nil)
            .appDestinations(.preview())
    }
}
