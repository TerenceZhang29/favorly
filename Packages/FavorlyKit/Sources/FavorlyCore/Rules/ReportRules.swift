import Foundation

public enum ReportRules {
    public static let maxNoteLength = 500

    /// Checks the note's length and returns it trimmed.
    @discardableResult
    public static func validateNote(_ note: String) throws -> String {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= maxNoteLength else {
            throw FavorlyError.validation("Note must be \(maxNoteLength) characters or fewer.")
        }
        return trimmed
    }

    /// Nobody reports or blocks themselves.
    public static func validateNotSelf(_ other: UserID, by user: UserID) throws {
        guard other != user else { throw FavorlyError.notAllowed }
    }
}
