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
        VStack(alignment: .leading, spacing: Theme.Spacing.section) {
            Spacer()
            Image(systemName: "heart.fill")
                .textStyle(.title)
                .foregroundStyle(Theme.Colors.onLime)
                .frame(width: Theme.IconSize.large, height: Theme.IconSize.large)
                .background(
                    Theme.Colors.lime,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Favorly")
                    .textStyle(.largeTitle)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityIdentifier("welcome.title")
                (Text("Ask neighbors for a small favor, or ")
                    + Text("lend a hand").foregroundStyle(Theme.Colors.brand)
                    + Text(" nearby."))
                    .textStyle(.cardTitle)
                    .foregroundStyle(Theme.Colors.ink)
            }
            WelcomeSamples()
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
        .background(GroveBackground())
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
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
        .disabled(viewModel.isSigningIn)
        .accessibilityIdentifier("welcome.signIn")
    }
}

#Preview {
    WelcomeView(environment: .preview())
}
