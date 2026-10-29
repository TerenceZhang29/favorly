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
                TextField("Title", text: $viewModel.title)
                    .submitLabel(.done)
                    .accessibilityIdentifier("post.title")
                if let titleMessage = viewModel.titleMessage {
                    InlineMessage(text: titleMessage, identifier: "post.titleMessage")
                }
                TextField("Details (optional)", text: $viewModel.details, axis: .vertical)
                    .lineLimit(3 ... 6)
                    .doneKey(text: $viewModel.details)
                    .accessibilityIdentifier("post.details")
                if let detailsMessage = viewModel.detailsMessage {
                    InlineMessage(text: detailsMessage, identifier: "post.detailsMessage")
                }
            } header: {
                SectionHeader(text: "What do you need?")
            }

            Section {
                Picker("Category", selection: $viewModel.category) {
                    ForEach(RequestCategory.allCases, id: \.self) { category in
                        Text(category.title).tag(category)
                    }
                }
                .accessibilityIdentifier("post.category")
            }

            Section {
                location
            } header: {
                SectionHeader(text: "Location")
            } footer: {
                if viewModel.locationText != nil {
                    Text("Neighbors see this with your request. Keep it general: a neighborhood, not an address.")
                }
            }

            if let submitError = viewModel.submitError {
                Section {
                    InlineMessage(text: submitError, identifier: "post.submitError")
                }
                .compactSectionSpacing()
            }

            Section {
                Button("Post request") {
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
        .navigationTitle("Post")
        .task(id: viewModel.reloadKey) { await viewModel.loadLocation() }
    }

    @ViewBuilder
    private var location: some View {
        switch viewModel.locationState {
        case .loading:
            ProgressView()
                .accessibilityIdentifier("post.locationLoading")
        case .tagged:
            Label {
                Text(viewModel.locationText ?? "")
            } icon: {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Theme.Colors.brand)
            }
            .accessibilityIdentifier("post.location")
            TextField("Neighborhood", text: $viewModel.locationLabel)
                .textContentType(.sublocality)
                .submitLabel(.done)
                .accessibilityLabel("Neighborhood")
                .accessibilityIdentifier("post.locationLabel")
            if let locationLabelMessage = viewModel.locationLabelMessage {
                InlineMessage(text: locationLabelMessage, identifier: "post.locationLabelMessage")
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
}

#Preview {
    NavigationStack {
        PostRequestView(environment: .preview()) { _ in }
    }
}
