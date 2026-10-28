import FavorlyCore
import SwiftUI

struct NearbyView: View {
    @State private var viewModel: NearbyViewModel
    @Environment(\.openURL) private var openURL

    init(environment: AppEnvironment) {
        _viewModel = State(initialValue: NearbyViewModel(environment: environment))
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.medium) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(Theme.Colors.brand)
                            .accessibilityHidden(true)
                        Text(viewModel.locationText ?? "Finding your location…")
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("nearby.location")
                    }
                    .font(.subheadline)
                    Picker("Radius", selection: $viewModel.radius) {
                        ForEach(RadiusOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("nearby.radiusPicker")
                }
                .padding(.vertical, Theme.Spacing.small)
            }

            Section {
                results
            } header: {
                if let countText = viewModel.countText {
                    SectionHeader(text: countText)
                        .accessibilityIdentifier("nearby.count")
                }
            }
        }
        .navigationTitle("Nearby")
        .refreshable { await viewModel.load() }
        .task(id: viewModel.reloadKey) { await viewModel.load() }
        .task { await viewModel.observeChanges() }
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
