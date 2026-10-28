import FavorlyCore
import SwiftUI

/// The thread between a request's requester and helper, newest message at the bottom.
struct ChatView: View {
    private let environment: AppEnvironment
    @State private var viewModel: ChatViewModel
    /// The message being reported, if any.
    @State private var reporting: MessageID?

    init(requestID: RequestID, environment: AppEnvironment) {
        self.environment = environment
        _viewModel = State(initialValue: ChatViewModel(requestID: requestID, environment: environment))
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                content
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages?.last?.id) { _, lastID in
                if let lastID {
                    withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.isOpenForSending {
                composer
            }
        }
        .sheet(isPresented: Binding(get: { reporting != nil }, set: {
            if !$0 {
                reporting = nil
            }
        })) {
            if let reporting {
                ReportView(target: .message(reporting), environment: environment)
            }
        }
        .navigationTitle(viewModel.title)
        .toolbarTitleDisplayMode(.inline)
        .task(id: viewModel.reloadKey) { await viewModel.load() }
        .task { await viewModel.observeChanges() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.section)
                .plainListRow()
                .accessibilityIdentifier("chat.loading")
        case let .loaded(messages):
            if messages.isEmpty {
                MessageView(
                    systemImage: "bubble.left.and.bubble.right",
                    message: viewModel.closedText == nil ? "Say hello" : "No messages",
                    messageIdentifier: "chat.empty"
                )
                .plainListRow()
            }
            ForEach(messages) { message in
                MessageBubble(
                    text: message.text,
                    senderName: viewModel.senderName(of: message),
                    timeText: message.sentAt.formatted(date: .omitted, time: .shortened),
                    isMine: viewModel.isMine(message)
                )
                .plainListRow()
                .id(message.id)
                .contextMenu {
                    if !viewModel.isMine(message) {
                        Button("Report message", systemImage: "exclamationmark.bubble") {
                            reporting = message.id
                        }
                        .accessibilityIdentifier("chat.report")
                    }
                }
                .accessibilityIdentifier("chat.message.\(message.id.rawValue.uuidString)")
            }
            if let closedText = viewModel.closedText {
                Label(closedText, systemImage: "lock")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.xLarge)
                    .plainListRow()
                    .accessibilityIdentifier("chat.closed")
            }
        case let .failed(message):
            MessageView(
                systemImage: "exclamationmark.triangle",
                message: message,
                messageIdentifier: "chat.error",
                retryIdentifier: "chat.retry"
            ) {
                Task { await viewModel.load() }
            }
            .plainListRow()
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            if let sendError = viewModel.sendError {
                InlineMessage(text: sendError, identifier: "chat.sendError")
            }
            if let draftMessage = viewModel.draftMessage {
                InlineMessage(text: draftMessage, identifier: "chat.draftMessage")
            }
            HStack(alignment: .bottom, spacing: Theme.Spacing.medium) {
                TextField("Message", text: $viewModel.draft, axis: .vertical)
                    .lineLimit(1 ... 4)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("chat.input")
                Button("Send") {
                    Task { await viewModel.send() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.Colors.brand)
                .disabled(!viewModel.canSend)
                .accessibilityIdentifier("chat.send")
            }
            if let draftCountText = viewModel.draftCountText {
                Text(draftCountText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("chat.count")
            }
        }
        .padding(.horizontal, Theme.Spacing.xLarge)
        .padding(.vertical, Theme.Spacing.medium)
        .background(.bar)
    }
}

#Preview {
    NavigationStack {
        ChatView(requestID: RequestID(rawValue: UUID()), environment: .preview())
    }
}
