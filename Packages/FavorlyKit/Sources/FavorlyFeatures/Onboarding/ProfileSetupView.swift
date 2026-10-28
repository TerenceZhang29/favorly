import SwiftUI

/// Sign-up after Sign in with Apple: a display name, the age check and the terms.
struct ProfileSetupView: View {
    @State private var viewModel: ProfileSetupViewModel

    init(environment: AppEnvironment) {
        _viewModel = State(initialValue: ProfileSetupViewModel(environment: environment))
    }

    var body: some View {
        Form {
            Section {
                TextField("First name or nickname", text: $viewModel.displayName)
                    .textContentType(.givenName)
                    .submitLabel(.done)
                    .accessibilityIdentifier("setup.name")
                if let nameMessage = viewModel.nameMessage {
                    InlineMessage(text: nameMessage, identifier: "setup.nameMessage")
                }
            } header: {
                SectionHeader(text: "Your name")
            } footer: {
                Text("Neighbors see this name on your requests and reviews.")
            }

            Section {
                Toggle("I'm 18 or older", isOn: $viewModel.confirmedAdult)
                    .accessibilityIdentifier("setup.adult")
                Toggle("I accept the Terms of Use and Privacy Policy", isOn: $viewModel.acceptedTerms)
                    .accessibilityIdentifier("setup.terms")
                Link("Read the Terms of Use", destination: LegalLinks.terms)
                    .accessibilityIdentifier("setup.termsLink")
                Link("Read the Privacy Policy", destination: LegalLinks.privacy)
                    .accessibilityIdentifier("setup.privacyLink")
            } header: {
                SectionHeader(text: "Before you start")
            }

            if let submitError = viewModel.submitError {
                Section {
                    InlineMessage(text: submitError, identifier: "setup.submitError")
                }
                .compactSectionSpacing()
            }

            Section {
                Button("Continue") {
                    Task { await viewModel.submit() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.canContinue)
                .accessibilityIdentifier("setup.continue")
                .plainListRow()
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Create your profile")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    Task { await viewModel.cancel() }
                }
                .accessibilityIdentifier("setup.cancel")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSetupView(environment: .preview())
    }
}
