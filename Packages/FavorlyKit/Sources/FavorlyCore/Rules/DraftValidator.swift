import Foundation

public enum DraftValidator {
    public static let titleLengthRange = 3 ... 80
    public static let maxDetailsLength = 500

    /// Checks the title and details limits and returns the draft with both trimmed.
    @discardableResult
    public static func validate(_ draft: NewRequestDraft) throws -> NewRequestDraft {
        var normalized = draft
        normalized.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.details = draft.details.trimmingCharacters(in: .whitespacesAndNewlines)

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
}
