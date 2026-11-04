import Foundation

public enum DraftValidator {
    public static let titleLengthRange = 3 ... 80
    public static let maxDetailsLength = 500
    public static let maxLocationLabelLength = 40
    public static let maxMeetingSpotLength = 40
    /// Letters, spaces and a little punctuation: no digits, so no house numbers or street addresses. The server
    /// applies the same pattern (`private.check_location_label`, `private.check_meeting_spot`).
    static let placeCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: " ,.-'’"))

    /// Checks the title, details, neighborhood and meeting spot, and returns the draft with all four trimmed.
    /// Whether the neighborhood is one offered for the point is `NeighborhoodDirectory`'s question.
    @discardableResult
    public static func validate(_ draft: NewRequestDraft) throws -> NewRequestDraft {
        var normalized = draft
        normalized.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.details = draft.details.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.location = try TaggedLocation(
            point: draft.location.point,
            label: validateLocationLabel(draft.location.label)
        )
        normalized.meetingSpot = try validateMeetingSpot(draft.meetingSpot)

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
    /// and simple punctuation only, and through the content filter. In NYC it is also one of the offered names.
    @discardableResult
    public static func validateLocationLabel(_ label: String) throws -> String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw FavorlyError.validation("Add a neighborhood for your request.")
        }
        guard trimmed.count <= maxLocationLabelLength else {
            throw FavorlyError.validation("Neighborhood must be \(maxLocationLabelLength) characters or fewer.")
        }
        guard trimmed.unicodeScalars.allSatisfy(placeCharacters.contains) else {
            throw FavorlyError.validation("Use only letters for the neighborhood, not a street address.")
        }
        try ContentFilter.validate(trimmed)
        return trimmed
    }

    /// Where to meet, such as "Cornell Tech lobby": optional, trimmed, at most 40 characters, letters and simple
    /// punctuation only (no house or unit numbers), and through the content filter.
    @discardableResult
    public static func validateMeetingSpot(_ spot: String) throws -> String {
        let trimmed = spot.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        guard trimmed.count <= maxMeetingSpotLength else {
            throw FavorlyError.validation("Meeting spot must be \(maxMeetingSpotLength) characters or fewer.")
        }
        guard trimmed.unicodeScalars.allSatisfy(placeCharacters.contains) else {
            throw FavorlyError.validation("Use only letters for the meeting spot, not a street address.")
        }
        try ContentFilter.validate(trimmed)
        return trimmed
    }

    /// Refuses a neighborhood that is not among `choices`, the names offered for the request's point. No choices
    /// means no data for that place, and any label is fine.
    public static func validateNeighborhood(_ label: String, among choices: [String]) throws {
        guard choices.isEmpty || choices.contains(label) else {
            throw FavorlyError.validation("Choose a neighborhood near you.")
        }
    }
}
