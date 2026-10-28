import FavorlyCore
import Observation

/// The profile a new user fills in after signing in: a name, their age, and the terms.
@MainActor
@Observable
final class ProfileSetupViewModel {
    var displayName = ""
    var confirmedAdult = false
    var acceptedTerms = false
    private(set) var isSubmitting = false
    /// Why the last submit failed.
    private(set) var submitError: String?

    @ObservationIgnored private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    private var draft: ProfileSetupDraft {
        ProfileSetupDraft(displayName: displayName, confirmedAdult: confirmedAdult, acceptedTerms: acceptedTerms)
    }

    /// What is wrong with the name, once the user has typed something.
    var nameMessage: String? {
        guard !displayName.isEmpty else { return nil }
        let nameOnly = ProfileSetupDraft(displayName: displayName, confirmedAdult: true, acceptedTerms: true)
        return validationMessage(for: nameOnly)
    }

    var canContinue: Bool {
        !isSubmitting && validationMessage(for: draft) == nil
    }

    func submit() async {
        guard canContinue else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        submitError = nil

        do {
            try await environment.auth.completeProfile(draft)
        } catch is CancellationError {
            // The screen went away.
        } catch {
            submitError = ErrorMessage.text(for: error)
        }
    }

    /// Back to the Welcome screen without creating a profile.
    func cancel() async {
        await environment.auth.signOut()
    }

    private func validationMessage(for draft: ProfileSetupDraft) -> String? {
        do {
            try ProfileSetupRules.validate(draft)
            return nil
        } catch {
            return ErrorMessage.text(for: error)
        }
    }
}
