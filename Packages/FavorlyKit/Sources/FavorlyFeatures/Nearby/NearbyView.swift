import FavorlyCore
import SwiftUI

struct NearbyView: View {
    @State private var viewModel: NearbyViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.selectTab) private var selectTab
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The location beside the score pill, or above it at accessibility text sizes so words don't break.
    private var headerLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.medium))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Theme.Spacing.medium))
    }

    init(environment: AppEnvironment) {
        _viewModel = State(initialValue: NearbyViewModel(environment: environment))
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: Theme.Spacing.xLarge) {
                    headerLayout {
                        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.small) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(Theme.Colors.inkMuted)
                                .accessibilityHidden(true)
                            Text(viewModel.locationText ?? "Finding your location…")
                                .foregroundStyle(Theme.Colors.inkMuted)
                                .accessibilityIdentifier("nearby.location")
                        }
                        .textStyle(.meta)
                        if !dynamicTypeSize.isAccessibilitySize {
                            Spacer(minLength: Theme.Spacing.medium)
                        }
                        if let score = viewModel.score {
                            scorePill(score)
                        }
                    }
                    ScreenHeadline(text: "Neighbors who\ncould use ", accent: "a hand")
                    Picker("Radius", selection: $viewModel.radius) {
                        ForEach(RadiusOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("nearby.radiusPicker")
                }
                .padding(.vertical, Theme.Spacing.small)
                .listRowInsets(EdgeInsets(
                    top: Theme.Spacing.small,
                    leading: Theme.Spacing.screen,
                    bottom: Theme.Spacing.small,
                    trailing: Theme.Spacing.screen
                ))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                results
            } header: {
                // The mockup shows no count; VoiceOver still reads it.
                if let countText = viewModel.countText {
                    SpokenOnlyText(text: countText, identifier: "nearby.count")
                }
            }
        }
        .listStyle(.plain)
        .groveListBackground()
        .navigationTitle("Nearby")
        .hidingNavigationBar()
        .refreshable { await viewModel.load() }
        .task(id: viewModel.reloadKey) { await viewModel.load() }
        .task { await viewModel.observeChanges() }
    }

    /// The mockup's lime score pill. Tapping it opens the Profile tab.
    private func scorePill(_ score: Int) -> some View {
        Button {
            selectTab(.profile)
        } label: {
            Label(score.formatted(), systemImage: "star.fill")
                .textStyle(.metaStrong)
                .foregroundStyle(Theme.Colors.onLime)
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.vertical, Theme.Spacing.small + Theme.Spacing.small / 2)
                .background(Theme.Colors.lime, in: Capsule())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Kindness score")
        .accessibilityValue("\(score) points")
        .accessibilityHint("Opens your profile.")
        .accessibilityIdentifier("nearby.score")
    }

    @ViewBuilder
    private var results: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.section)
                .plainListRow()
                .accessibilityIdentifier("nearby.loading")
        case let .loaded(items):
            ForEach(items) { item in
                NavigationLink(value: item.id) {
                    RequestRow(
                        item: item,
                        requesterName: viewModel.requesterName(for: item.request),
                        isOwn: viewModel.isOwn(item.request)
                    )
                }
                .cardRow()
                .navigationLinkIndicatorVisibility(.hidden)
                .accessibilityIdentifier("nearby.row.\(item.id.rawValue.uuidString)")
            }
        case .empty:
            MessageView(systemImage: "tray", message: viewModel.emptyMessage, messageIdentifier: "nearby.empty")
                .plainListRow()
        case let .failed(message):
            MessageView(
                systemImage: "wifi.exclamationmark",
                message: message,
                messageIdentifier: "nearby.error",
                retryIdentifier: "nearby.retry"
            ) {
                Task { await viewModel.load() }
            }
            .plainListRow()
        case let .locationDenied(message):
            MessageView(
                systemImage: "location.slash",
                message: message,
                messageIdentifier: "nearby.locationDenied",
                retryIdentifier: "nearby.openSettings",
                actionTitle: "Open Settings"
            ) {
                if let url = SystemSettings.appURL {
                    openURL(url)
                }
            }
            .plainListRow()
        }
    }
}

#Preview {
    NavigationStack {
        NearbyView(environment: .preview())
            .appDestinations(.preview())
    }
}
