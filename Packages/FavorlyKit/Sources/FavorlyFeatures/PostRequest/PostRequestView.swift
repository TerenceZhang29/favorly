import FavorlyCore
import SwiftUI

struct PostRequestView: View {
    @State private var viewModel: PostRequestViewModel
    @Environment(\.openURL) private var openURL
    private let onPosted: (HelpRequest) -> Void

    init(environment: AppEnvironment, onPosted: @escaping (HelpRequest) -> Void) {
        _viewModel = State(initialValue: PostRequestViewModel(environment: environment))
        self.onPosted = onPosted
    }

    var body: some View {
        Form {
            Section {
                ScreenHeadline(text: "Ask for ", accent: "a favor")
                    .padding(.horizontal, Theme.Spacing.screen + Theme.Spacing.small)
                    .padding(.top, Theme.Spacing.section)
                    .plainListRow()
            }

            Section {
                TextField("Title", text: $viewModel.title)
                    .submitLabel(.done)
                    .accessibilityIdentifier("post.title")
                if let titleMessage = viewModel.titleMessage {
                    InlineMessage(text: titleMessage, identifier: "post.titleMessage")
                }
            } header: {
                SectionHeader(text: "What do you need?")
            }
            .groveRows()

            // Details get their own card, with a running count, as in the mockup.
            Section {
                TextField("Details (optional)", text: $viewModel.details, axis: .vertical)
                    .lineLimit(3 ... 6)
                    .doneKey(text: $viewModel.details)
                    .accessibilityIdentifier("post.details")
                if let detailsMessage = viewModel.detailsMessage {
                    InlineMessage(text: detailsMessage, identifier: "post.detailsMessage")
                }
            } footer: {
                Text("\(viewModel.details.count) / \(DraftValidator.maxDetailsLength)")
                    .textStyle(.meta)
                    .foregroundStyle(Theme.Colors.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityIdentifier("post.detailsCount")
            }
            .groveRows()
            .compactSectionSpacing()

            // Category chips, as in the mockup: one tap picks a category.
            Section {
                FlowLayout {
                    ForEach(RequestCategory.allCases, id: \.self) { category in
                        categoryChip(category)
                    }
                }
                .padding(.horizontal, Theme.Spacing.screen + Theme.Spacing.small)
                .plainListRow()
            } header: {
                SectionHeader(text: "Category")
            }

            Section {
                location
            } header: {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(text: "Location")
                    // The mockup shows only the neighborhood and meeting spot; VoiceOver still reads the tag.
                    if case .tagged = viewModel.locationState, let locationText = viewModel.locationText {
                        SpokenOnlyText(text: locationText, identifier: "post.location")
                    }
                }
            } footer: {
                if viewModel.locationText != nil {
                    Text("Neighbors see these with your request. Pick a public meeting spot, never an address.")
                        .textStyle(.meta)
                        .foregroundStyle(Theme.Colors.inkMuted)
                }
            }
            .groveRows()

            if let submitError = viewModel.submitError {
                Section {
                    InlineMessage(text: submitError, identifier: "post.submitError")
                }
                .compactSectionSpacing()
            }

            Section {
                Button("Post request") {
                    // Posting opens My Activity; without this the keyboard stays open over it.
                    Keyboard.dismiss()
                    Task {
                        if let request = await viewModel.submit() {
                            onPosted(request)
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.canSubmit)
                .accessibilityIdentifier("post.submit")
                .plainListRow()
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .groveListBackground()
        .navigationTitle("Post")
        .hidingNavigationBar()
        .task(id: viewModel.reloadKey) { await viewModel.loadLocation() }
    }

    private func categoryChip(_ category: RequestCategory) -> some View {
        let isSelected = viewModel.category == category
        return Button {
            viewModel.category = category
        } label: {
            HStack(spacing: Theme.Spacing.small + Theme.Spacing.small / 2) {
                Image(systemName: category.systemImage)
                    .accessibilityHidden(true)
                Text(category.title)
            }
            .textStyle(isSelected ? .bodyStrong : .body)
            .fixedSize()
            .foregroundStyle(isSelected ? Theme.Colors.onBubbleMine : Theme.Colors.ink)
            .padding(.horizontal, Theme.Spacing.large)
            .frame(minHeight: Theme.pillHeight)
            .background(isSelected ? Theme.Colors.bubbleMine : Theme.Colors.surface, in: Capsule())
            .overlay {
                if !isSelected {
                    Capsule().strokeBorder(Theme.Colors.surfaceBorder, lineWidth: Theme.borderWidth)
                }
            }
        }
        .buttonStyle(ChipButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("post.category.\(category.rawValue)")
    }

    @ViewBuilder
    private var location: some View {
        switch viewModel.locationState {
        case .loading:
            ProgressView()
                .accessibilityIdentifier("post.locationLoading")
        case .tagged:
            neighborhood
            TextField("Meeting spot (optional)", text: $viewModel.meetingSpot)
                .submitLabel(.done)
                .accessibilityLabel("Meeting spot")
                .accessibilityIdentifier("post.meetingSpot")
            if let meetingSpotMessage = viewModel.meetingSpotMessage {
                InlineMessage(text: meetingSpotMessage, identifier: "post.meetingSpotMessage")
            }
        case let .failed(message):
            InlineMessage(text: message, identifier: "post.locationError")
            Button("Retry") {
                Task { await viewModel.loadLocation() }
            }
            .accessibilityIdentifier("post.locationRetry")
        case let .denied(message):
            InlineMessage(text: message, identifier: "post.locationDenied")
            Button("Open Settings") {
                if let url = SystemSettings.appURL {
                    openURL(url)
                }
            }
            .accessibilityIdentifier("post.openSettings")
        }
    }

    @ViewBuilder
    private var neighborhood: some View {
        switch viewModel.neighborhoodState {
        case .loading:
            ProgressView("Finding neighborhoods…")
                .accessibilityIdentifier("post.neighborhoodLoading")
        case .loaded:
            Picker("Neighborhood", selection: $viewModel.neighborhood) {
                ForEach(viewModel.neighborhoodChoices, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("post.neighborhood")
        case let .failed(message):
            InlineMessage(text: message, identifier: "post.neighborhoodError")
            Button("Try again") {
                Task { await viewModel.loadNeighborhoods() }
            }
            .accessibilityIdentifier("post.neighborhood.retry")
        }
    }
}

#Preview {
    NavigationStack {
        PostRequestView(environment: .preview()) { _ in }
    }
}
