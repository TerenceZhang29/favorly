import Foundation

public enum ProfileSetupRules {
    public static let displayNameLengthRange = 2 ... 30
    /// The version of the Terms of Use a new user accepts. Raise it when the terms change.
    public static let termsVersion = 1

    /// Checks the name, age and terms, and returns the draft with the name trimmed.
    @discardableResult
    public static func validate(_ draft: ProfileSetupDraft) throws -> ProfileSetupDraft {
        var normalized = draft
        normalized.displayName = draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalized.displayName.count >= displayNameLengthRange.lowerBound else {
            throw FavorlyError.validation("Name must be at least \(displayNameLengthRange.lowerBound) characters.")
        }
        guard normalized.displayName.count <= displayNameLengthRange.upperBound else {
            throw FavorlyError.validation("Name must be \(displayNameLengthRange.upperBound) characters or fewer.")
        }
        try ContentFilter.validate(normalized.displayName)
        guard draft.confirmedAdult else {
            throw FavorlyError.validation("You must be 18 or older to use Favorly.")
        }
        guard draft.acceptedTerms else {
            throw FavorlyError.validation("Please accept the Terms of Use and Privacy Policy.")
        }
        return normalized
    }
}
