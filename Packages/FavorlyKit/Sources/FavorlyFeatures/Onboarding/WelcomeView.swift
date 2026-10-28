import AuthenticationServices
import SwiftUI

/// The first screen for someone who is signed out.
struct WelcomeView: View {
    @State private var viewModel: WelcomeViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(environment: AppEnvironment) {
        _viewModel = State(initialValue: WelcomeViewModel(environment: environment))
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.section) {
            Spacer()
            Image(systemName: "hands.sparkles.fill")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(Theme.Colors.brand)
                .accessibilityHidden(true)
            VStack(spacing: Theme.Spacing.medium) {
                Text("Favorly")
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("welcome.title")
                Text("Ask neighbors for a small favor, or lend a hand nearby.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            VStack(spacing: Theme.Spacing.large) {
                if let errorMessage = viewModel.errorMessage {
                    InlineMessage(text: errorMessage, identifier: "welcome.error")
                }
                if viewModel.usesAppleSignIn {
                    appleButton
                } else {
                    Button {
                        Task { await viewModel.signIn() }
                    } label: {
                        Label("Continue with Apple", systemImage: "apple.logo")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isSigningIn)
                    .accessibilityIdentifier("welcome.signIn")
                }
            }
        }
        .padding(Theme.Spacing.section)
    }

    /// Apple's own button, as App Review expects. It asks for no name or email: the profile asks for a name.
    private var appleButton: some View {
        SignInWithAppleButton(.continue) { request in
            request.requestedScopes = []
            request.nonce = viewModel.appleRequestNonce()
        } onCompletion: { result in
            switch result {
            case let .success(authorization):
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential
                Task { await viewModel.finishAppleSignIn(identityToken: credential?.identityToken) }
            case let .failure(error):
                viewModel.failAppleSignIn(error)
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: Theme.appleButtonHeight)
        .disabled(viewModel.isSigningIn)
        .accessibilityIdentifier("welcome.signIn")
    }
}

#Preview {
    WelcomeView(environment: .preview())
}
