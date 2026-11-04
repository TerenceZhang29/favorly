import FavorlyCore
import SwiftUI

struct BlockedUsersView: View {
    @State private var viewModel: BlockedUsersViewModel

    init(environment: AppEnvironment) {
        _viewModel = State(initialValue: BlockedUsersViewModel(environment: environment))
    }

    var body: some View {
        List {
            if let actionError = viewModel.actionError {
                Section {
                    InlineMessage(text: actionError, identifier: "blocked.error")
                }
                .groveRows()
            }
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .plainListRow()
                    .accessibilityIdentifier("blocked.loading")
            case let .loaded(users) where users.isEmpty:
                MessageView(
                    systemImage: "person.crop.circle.badge.checkmark",
                    message: "You haven't blocked anyone.",
                    messageIdentifier: "blocked.empty"
                )
                .plainListRow()
            case let .loaded(users):
                Section {
                    ForEach(users) { user in
                        HStack(spacing: Theme.Spacing.large) {
                            AvatarView(name: user.displayName, side: Theme.IconSize.row)
                            Text(user.displayName)
                                .textStyle(.bodyStrong)
                                .foregroundStyle(Theme.Colors.ink)
                            Spacer()
                            Button("Unblock") {
                                Task { await viewModel.unblock(user) }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .fixedSize()
                            .accessibilityIdentifier("blocked.unblock.\(user.id.rawValue)")
                        }
                    }
                } footer: {
                    Text("You and the people you block don't see each other's requests, messages or profiles.")
                        .textStyle(.meta)
                        .foregroundStyle(Theme.Colors.inkMuted)
                }
                .groveRows()
            case let .failed(message):
                MessageView(
                    systemImage: "exclamationmark.triangle",
                    message: message,
                    messageIdentifier: "blocked.loadError",
                    retryIdentifier: "blocked.retry"
                ) {
                    Task { await viewModel.load() }
                }
                .plainListRow()
            }
        }
        .groveListBackground()
        .navigationTitle("Blocked people")
        .task { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        BlockedUsersView(environment: .preview())
    }
}
