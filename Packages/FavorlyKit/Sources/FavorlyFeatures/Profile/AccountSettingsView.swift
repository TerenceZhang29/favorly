import SwiftUI

/// The account rows behind the gear on the Profile tab, as in the mockup: safety, notifications, legal links,
/// support, sign out and delete account. They used to sit at the bottom of the profile.
struct AccountSettingsView: View {
    let viewModel: ProfileViewModel
    let environment: AppEnvironment
    @State private var isConfirmingDelete = false

    var body: some View {
        List {
            if let accountError = viewModel.accountError {
                Section {
                    InlineMessage(text: accountError, identifier: "profile.accountError")
                }
                .groveRows()
            }
            Section {
                NavigationLink {
                    BlockedUsersView(environment: environment)
                } label: {
                    Label("Blocked people", systemImage: "hand.raised")
                }
                .accessibilityIdentifier("profile.blockedPeople")
                NavigationLink {
                    SafetyTipsView()
                } label: {
                    Label("Safety tips", systemImage: "checkmark.shield")
                }
                .accessibilityIdentifier("profile.safetyTips")
                if let settings = SystemSettings.appURL {
                    Link(destination: settings) {
                        Label("Notifications", systemImage: "bell")
                    }
                    .accessibilityIdentifier("profile.notifications")
                }
            } header: {
                SectionHeader(text: "Safety and notifications")
            }
            .groveRows()

            Section {
                Link(destination: LegalLinks.terms) {
                    Label("Terms of Use", systemImage: "doc.text")
                }
                .accessibilityIdentifier("profile.terms")
                Link(destination: LegalLinks.privacy) {
                    Label("Privacy Policy", systemImage: "lock")
                }
                .accessibilityIdentifier("profile.privacy")
                Link(destination: LegalLinks.support) {
                    Label("Contact support", systemImage: "envelope")
                }
                .accessibilityIdentifier("profile.support")
            } header: {
                SectionHeader(text: "Help and legal")
            }
            .groveRows()

            Section {
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
            .groveRows()
        }
        .groveListBackground()
        .navigationTitle("Settings")
        .toolbarTitleDisplayMode(.inline)
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
}
