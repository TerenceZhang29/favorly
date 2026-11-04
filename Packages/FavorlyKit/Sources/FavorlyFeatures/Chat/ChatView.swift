import FavorlyCore
import SwiftUI

/// The thread between a request's requester and helper, newest message at the bottom.
struct ChatView: View {
    private let environment: AppEnvironment
    @State private var viewModel: ChatViewModel
    /// The message being reported, if any.
    @State private var reporting: MessageID?
    @ScaledMetric private var composerHeight = Theme.composerHeight

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
            .groveListBackground()
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
                    .textStyle(.meta)
                    .foregroundStyle(Theme.Colors.inkMuted)
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
                    .textStyle(.body)
                    .padding(.horizontal, Theme.Spacing.xLarge)
                    .padding(.vertical, Theme.Spacing.medium + Theme.Spacing.small / 2)
                    .frame(minHeight: composerHeight)
                    .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: composerHeight / 2))
                    .overlay {
                        RoundedRectangle(cornerRadius: composerHeight / 2)
                            .strokeBorder(Theme.Colors.surfaceBorder, lineWidth: Theme.borderWidth)
                    }
                    .accessibilityIdentifier("chat.input")
                Button {
                    Task { await viewModel.send() }
                } label: {
                    Label("Send", systemImage: "arrow.up")
                        .labelStyle(.iconOnly)
                        .textStyle(.button)
                        .foregroundStyle(viewModel.canSend ? Theme.Colors.onBrand : Theme.Colors.inkMuted)
                        .frame(width: composerHeight, height: composerHeight)
                        .background(viewModel.canSend ? Theme.Colors.brand : Theme.Colors.segment, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canSend)
                .accessibilityIdentifier("chat.send")
            }
            if let draftCountText = viewModel.draftCountText {
                Text(draftCountText)
                    .textStyle(.meta)
                    .foregroundStyle(Theme.Colors.inkMuted)
                    .accessibilityIdentifier("chat.count")
            }
        }
        .padding(.horizontal, Theme.Spacing.xLarge)
        .padding(.vertical, Theme.Spacing.medium)
        .background(Theme.Colors.background)
    }
}

#Preview {
    NavigationStack {
        ChatView(requestID: RequestID(rawValue: UUID()), environment: .preview())
    }
}
