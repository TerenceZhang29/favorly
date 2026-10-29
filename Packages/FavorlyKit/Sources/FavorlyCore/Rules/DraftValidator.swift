import Foundation

public enum DraftValidator {
    public static let titleLengthRange = 3 ... 80
    public static let maxDetailsLength = 500
    public static let maxLocationLabelLength = 40
    /// Letters, spaces and a little punctuation: no digits, so no house numbers or street addresses. The server
    /// applies the same pattern (`private.check_location_label`).
    static let locationLabelCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: " ,.-'’"))

    /// Checks the title, details and neighborhood, and returns the draft with all three trimmed.
    @discardableResult
    public static func validate(_ draft: NewRequestDraft) throws -> NewRequestDraft {
        var normalized = draft
        normalized.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.details = draft.details.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.location = TaggedLocation(
            point: draft.location.point,
            label: try validateLocationLabel(draft.location.label)
        )

        guard normalized.title.count >= titleLengthRange.lowerBound else {
            throw FavorlyError.validation("Title must be at least \(titleLengthRange.lowerBound) characters.")
        }
        guard normalized.title.count <= titleLengthRange.upperBound else {
            throw FavorlyError.validation("Title must be \(titleLengthRange.upperBound) characters or fewer.")
        }
        guard normalized.details.count <= maxDetailsLength else {
            throw FavorlyError.validation("Details must be \(maxDetailsLength) characters or fewer.")
        }
        try ContentFilter.validate(normalized.title + " " + normalized.details)
        return normalized
    }

    /// The neighborhood shown with a request, such as "Roosevelt Island": trimmed, at most 40 characters, letters
    /// and simple punctuation only, and through the content filter.
    @discardableResult
    public static func validateLocationLabel(_ label: String) throws -> String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw FavorlyError.validation("Add a neighborhood for your request.")
        }
        guard trimmed.count <= maxLocationLabelLength else {
            throw FavorlyError.validation("Neighborhood must be \(maxLocationLabelLength) characters or fewer.")
        }
        guard trimmed.unicodeScalars.allSatisfy(locationLabelCharacters.contains) else {
            throw FavorlyError.validation("Use only letters for the neighborhood, not a street address.")
        }
        try ContentFilter.validate(trimmed)
        return trimmed
    }
}
