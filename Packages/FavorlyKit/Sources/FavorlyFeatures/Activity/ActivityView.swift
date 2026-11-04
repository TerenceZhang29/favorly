import FavorlyCore
import SwiftUI

struct ActivityView: View {
    /// The request that was just posted, shown highlighted.
    private let highlightedRequestID: RequestID?
    @State private var viewModel: ActivityViewModel

    init(environment: AppEnvironment, highlightedRequestID: RequestID?) {
        self.highlightedRequestID = highlightedRequestID
        _viewModel = State(initialValue: ActivityViewModel(environment: environment))
    }

    var body: some View {
        List {
            Section {
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

            Section {
                results
            }
        }
        .listStyle(.plain)
        .groveListBackground()
        .navigationTitle("My Activity")
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
                NavigationLink(value: request.id) {
                    ActivityRow(request: request, subtitle: viewModel.subtitle(for: request), isNew: isNew)
                }
                .cardRow(isHighlighted: isNew)
                .accessibilityIdentifier("activity.row.\(request.id.rawValue.uuidString)")
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

#Preview {
    NavigationStack {
        ActivityView(environment: .preview(), highlightedRequestID: nil)
            .appDestinations(.preview())
    }
}
