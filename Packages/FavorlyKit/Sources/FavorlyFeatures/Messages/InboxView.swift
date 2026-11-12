import SwiftUI

/// The Messages tab: every conversation the user is in, newest first, filtered to all, their requests or the ones
/// they are helping with. Tapping one opens its chat.
struct InboxView: View {
    @Bindable var model: InboxModel

    var body: some View {
        List {
            Section {
                ScreenHeadline(text: "Messages")
                    .padding(.horizontal, Theme.Spacing.screen)
                    .padding(.top, Theme.Spacing.section)
                    .plainListRow()
                Picker("Show", selection: $model.filter) {
                    ForEach(InboxFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("inbox.filter")
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
        .navigationTitle("Messages")
        .hidingNavigationBar()
        .refreshable { await model.load() }
    }

    @ViewBuilder
    private var results: some View {
        if case let .failed(message) = model.state {
            MessageView(
                systemImage: "exclamationmark.triangle",
                message: message,
                messageIdentifier: "inbox.error",
                retryIdentifier: "inbox.retry"
            ) {
                Task { await model.load() }
            }
            .plainListRow()
        } else if let threads = model.visibleThreads {
            if threads.isEmpty {
                MessageView(
                    systemImage: "bubble.left.and.bubble.right",
                    message: model.filter.emptyMessage,
                    messageIdentifier: "inbox.empty"
                )
                .plainListRow()
            }
            ForEach(threads) { thread in
                NavigationLink(value: ChatDestination(requestID: thread.requestID)) {
                    InboxRow(thread: thread, timeText: model.timeText(for: thread))
                }
                .buttonStyle(.plain)
                .navigationLinkIndicatorVisibility(.hidden)
                .accessibilityIdentifier("inbox.row.\(thread.requestID.rawValue.uuidString)")
                .cardRow()
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.section)
                .plainListRow()
                .accessibilityIdentifier("inbox.loading")
        }
    }
}
