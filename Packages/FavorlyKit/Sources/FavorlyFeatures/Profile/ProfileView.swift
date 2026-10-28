import FavorlyCore
import SwiftUI

/// The Profile tab for the signed-in user, or another user's profile pushed from Request Detail.
struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    @State private var isConfirmingDelete = false
    /// True for the Profile tab, false when pushed for a given user.
    private let isTab: Bool

    /// - Parameter userID: The user to show, or nil for whoever is signed in.
    init(userID: UserID? = nil, environment: AppEnvironment) {
        _viewModel = State(initialValue: ProfileViewModel(userID: userID, environment: environment))
        isTab = userID == nil
    }

    var body: some View {
        List {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.section)
                    .plainListRow()
                    .accessibilityIdentifier("profile.loading")
            case let .loaded(content):
                header(content.user)
                score
                activities(content.activities)
                reviews(content.reviews)
                if viewModel.showsAccount {
                    account
                }
            case let .failed(message):
                MessageView(
                    systemImage: "exclamationmark.triangle",
                    message: message,
                    messageIdentifier: "profile.error",
                    retryIdentifier: "profile.retry"
                ) {
                    Task { await viewModel.load() }
                }
                .plainListRow()
            }
        }
        .navigationTitle(isTab ? "Profile" : viewModel.content?.user.displayName ?? "Profile")
        .toolbarTitleDisplayMode(isTab ? .automatic : .inline)
        .refreshable { await viewModel.load() }
        .task(id: viewModel.reloadKey) { await viewModel.load() }
        .task { await viewModel.observeChanges() }
    }

    private func header(_ user: UserProfile) -> some View {
        Section {
            HStack(spacing: Theme.Spacing.xLarge) {
                AvatarView(name: user.displayName, color: user.id.avatarColor)
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text(user.displayName)
                        .font(.title2.bold())
                        .accessibilityIdentifier("profile.name")
                    if !user.neighborhood.isEmpty {
                        Label(user.neighborhood, systemImage: "mappin")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("profile.neighborhood")
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.medium)
        }
    }

    private var score: some View {
        Section {
            ScoreLabel(points: viewModel.content?.summary.lifetimePoints ?? 0, isLarge: true)
                .accessibilityIdentifier("profile.score")
            Label(viewModel.favorsText, systemImage: "hands.sparkles")
                .accessibilityIdentifier("profile.favors")
            Label(viewModel.ratingText, systemImage: "star")
                .accessibilityIdentifier("profile.rating")
        } header: {
            SectionHeader(text: "Kindness score")
        }
    }

    private var account: some View {
        Section {
            if let accountError = viewModel.accountError {
                InlineMessage(text: accountError, identifier: "profile.accountError")
            }
            Button("Sign out") {
                Task { await viewModel.signOut() }
            }
            .accessibilityIdentifier("profile.signOut")
            Button("Delete account", role: .destructive) {
                isConfirmingDelete = true
            }
            .disabled(viewModel.isDeletingAccount)
            .accessibilityIdentifier("profile.deleteAccount")
        } header: {
            SectionHeader(text: "Account")
        }
        .confirmationDialog("Delete your account?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) {
                Task { await viewModel.deleteAccount() }
            }
            .accessibilityIdentifier("profile.confirmDelete")
        } message: {
            Text(Self.deleteExplanation)
        }
    }

    static let deleteExplanation = """
    This deletes your profile, your open requests, and the messages and reviews you wrote. \
    Favors you completed stay, shown as from a deleted user. This can't be undone.
    """

    private func reviews(_ reviews: [Review]) -> some View {
        Section {
            if reviews.isEmpty {
                Text("No reviews yet")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("profile.reviewsEmpty")
            }
            ForEach(reviews) { review in
                ReviewRow(
                    rating: review.rating,
                    comment: review.comment,
                    reviewerName: viewModel.displayName(for: review.reviewerID),
                    dateText: review.createdAt.formatted(.dateTime.month(.abbreviated).day())
                )
                .accessibilityIdentifier("profile.review.\(review.id.rawValue.uuidString)")
            }
        } header: {
            SectionHeader(text: "Reviews")
        }
    }

    private func activities(_ activities: [ProfileActivity]) -> some View {
        Section {
            if activities.isEmpty {
                MessageView(systemImage: "sparkles", message: "No activity yet", messageIdentifier: "profile.empty")
                    .plainListRow()
            }
            ForEach(activities) { activity in
                NavigationLink(value: activity.id) {
                    ProfileActivityRow(request: activity.request, roleTitle: activity.role.title)
                }
                .accessibilityIdentifier("profile.activity.\(activity.id.rawValue.uuidString)")
            }
        } header: {
            SectionHeader(text: "Past activities")
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(environment: .preview())
            .appDestinations(.preview())
    }
}
