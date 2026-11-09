import FavorlyCore
import SwiftUI

/// The Profile tab for the signed-in user, or another user's profile pushed from Request Detail.
struct ProfileView: View {
    private let environment: AppEnvironment
    @State private var viewModel: ProfileViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.selectTab) private var selectTab
    @State private var isShowingSettings = false
    /// True for the Profile tab, false when pushed for a given user.
    private let isTab: Bool

    /// - Parameter userID: The user to show, or nil for whoever is signed in.
    init(userID: UserID? = nil, environment: AppEnvironment) {
        self.environment = environment
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
                if isTab {
                    milestone
                }
                activities(content.activities)
                reviews(content.reviews)
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
        .groveListBackground()
        .navigationTitle(isTab ? "Profile" : viewModel.content?.user.displayName ?? "Profile")
        .toolbarTitleDisplayMode(isTab ? .automatic : .inline)
        .modifier(TabRootBar(isTabRoot: isTab))
        .navigationDestination(isPresented: $isShowingSettings) {
            AccountSettingsView(viewModel: viewModel, environment: environment)
        }
        .modifier(SafetyActions(
            isEnabled: viewModel.canReportOrBlock,
            reportTitle: "Report \(personName)",
            personName: personName,
            identifier: "profile",
            reportTarget: .user(viewModel.userID),
            environment: environment,
            block: viewModel.block
        ))
        .refreshable { await viewModel.load() }
        .task(id: viewModel.reloadKey) { await viewModel.load() }
        .task { await viewModel.observeChanges() }
    }

    /// The name in the report and block menu: the person's name once loaded.
    private var personName: String {
        viewModel.content?.user.displayName ?? "this person"
    }

    private func header(_ user: UserProfile) -> some View {
        Section {
            VStack(spacing: Theme.Spacing.medium) {
                if isTab {
                    // The mockup's settings button, top right, over the avatar.
                    HStack {
                        Spacer()
                        Button {
                            isShowingSettings = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: Theme.IconSize.tabSymbol, weight: .semibold))
                                .foregroundStyle(Theme.Colors.ink)
                                .frame(width: Theme.composerHeight, height: Theme.composerHeight)
                                .background(
                                    Theme.Colors.surface,
                                    in: RoundedRectangle(cornerRadius: Theme.Radius.field)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: Theme.Radius.field)
                                        .strokeBorder(Theme.Colors.surfaceBorder, lineWidth: Theme.borderWidth)
                                }
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Settings")
                        .accessibilityIdentifier("profile.settings")
                    }
                    .padding(.horizontal, Theme.Spacing.screen)
                }
                avatar(for: user)
                Text(user.displayName)
                    .textStyle(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("profile.name")
                if !user.neighborhood.isEmpty {
                    Label(user.neighborhood, systemImage: "mappin")
                        .textStyle(.body)
                        .foregroundStyle(Theme.Colors.inkMuted)
                        .accessibilityIdentifier("profile.neighborhood")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.small)
            .plainListRow()
        }
    }

    /// The avatar, with the mockup's progress ring toward the next milestone on the user's own profile.
    @ViewBuilder
    private func avatar(for user: UserProfile) -> some View {
        if isTab {
            AvatarView(name: user.displayName)
                .padding(Theme.Spacing.small + Theme.Spacing.small / 2)
                .overlay {
                    Circle().stroke(Theme.Colors.surfaceBorder, lineWidth: Theme.ringWidth)
                    Circle()
                        .trim(from: 0, to: viewModel.milestoneProgress)
                        .stroke(Theme.Colors.star, style: StrokeStyle(lineWidth: Theme.ringWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .accessibilityElement()
                .accessibilityLabel("Next milestone")
                .accessibilityValue(viewModel.milestoneText)
        } else {
            AvatarView(name: user.displayName)
        }
    }

    /// The mockup's gift card, as progress only: 1.0 has no reward to redeem, so there is no Redeem button.
    private var milestone: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                HStack(spacing: Theme.Spacing.large) {
                    IconTile(systemImage: "gift")
                    VStack(alignment: .leading, spacing: Theme.Spacing.small / 2) {
                        Text("Next milestone")
                            .textStyle(.bodyStrong)
                            .foregroundStyle(Theme.Colors.ink)
                        Text(viewModel.milestoneText)
                            .textStyle(.meta)
                            .foregroundStyle(Theme.Colors.inkMuted)
                    }
                }
                ProgressView(value: viewModel.milestoneProgress)
                    .tint(Theme.Colors.star)
                    .accessibilityHidden(true)
                Text(viewModel.milestoneRemainingText)
                    .textStyle(.meta)
                    .foregroundStyle(Theme.Colors.inkMuted)
            }
            .padding(.vertical, Theme.Spacing.small)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("profile.milestone")
        }
        .groveRows()
    }

    /// One card, as in the mockup: the lime "Kindness score" badge over the score, and favors and rating beside
    /// it (under it at accessibility text sizes).
    private var score: some View {
        Section {
            scoreLayout {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    TagBadge(text: "Kindness score")
                        .accessibilityHidden(true)
                    ScoreLabel(points: viewModel.content?.summary.lifetimePoints ?? 0, isLarge: true)
                        .accessibilityIdentifier("profile.score")
                }
                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer(minLength: Theme.Spacing.medium)
                }
                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    Label(viewModel.favorsText, systemImage: "hands.sparkles")
                        .accessibilityIdentifier("profile.favors")
                    Label(viewModel.ratingText, systemImage: "star")
                        .accessibilityIdentifier("profile.rating")
                }
                .textStyle(.meta)
                .foregroundStyle(Theme.Colors.ink)
            }
            .padding(.vertical, Theme.Spacing.small)
        }
        .groveRows()
    }

    private var scoreLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.large))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Theme.Spacing.large))
    }

    private func reviews(_ reviews: [Review]) -> some View {
        Section {
            if reviews.isEmpty {
                Text("No reviews yet")
                    .foregroundStyle(Theme.Colors.inkMuted)
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
        .groveRows()
    }

    private func activities(_ activities: [ProfileActivity]) -> some View {
        Section {
            if activities.isEmpty {
                MessageView(systemImage: "sparkles", message: "No activity yet", messageIdentifier: "profile.empty")
                    .plainListRow()
            }
            ForEach(activities) { activity in
                NavigationLink(value: activity.id) {
                    ProfileActivityRow(
                        request: activity.request,
                        role: activity.role,
                        pointsText: viewModel.pointsText(for: activity)
                    )
                }
                .navigationLinkIndicatorVisibility(.hidden)
                .accessibilityIdentifier("profile.activity.\(activity.id.rawValue.uuidString)")
            }
        } header: {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader(text: "Past activities")
                Spacer()
                if isTab {
                    Button("See all") { selectTab(.activity) }
                        .textStyle(.meta)
                        .foregroundStyle(Theme.Colors.inkMuted)
                        .textCase(nil)
                        .accessibilityIdentifier("profile.seeAll")
                }
            }
        }
        .groveRows()
    }
}

#Preview {
    NavigationStack {
        ProfileView(environment: .preview())
            .appDestinations(.preview())
    }
}
