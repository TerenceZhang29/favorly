import Foundation

/// Who can read and write a request's thread.
public enum ChatRules {
    public static let messageLengthRange = 1 ... 500

    /// A thread exists once the request has a helper, and only the requester and the helper can read it.
    public static func validateRead(request: HelpRequest, by user: UserID) throws {
        guard let helperID = request.helperID, user == request.requesterID || user == helperID else {
            throw FavorlyError.notAllowed
        }
    }

    /// Sending is allowed only while the request is claimed; after completion or cancellation the thread is read-only.
    public static func validateSend(request: HelpRequest, by user: UserID) throws {
        try validateRead(request: request, by: user)
        guard request.status == .claimed else { throw FavorlyError.notAllowed }
    }

    public static func canRead(request: HelpRequest, by user: UserID) -> Bool {
        (try? validateRead(request: request, by: user)) != nil
    }

    public static func canSend(request: HelpRequest, by user: UserID) -> Bool {
        (try? validateSend(request: request, by: user)) != nil
    }

    /// Checks the length limits and returns the text trimmed.
    @discardableResult
    public static func validateText(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= messageLengthRange.lowerBound else {
            throw FavorlyError.validation("Message can't be empty.")
        }
        guard trimmed.count <= messageLengthRange.upperBound else {
            throw FavorlyError.validation("Message must be \(messageLengthRange.upperBound) characters or fewer.")
        }
        try ContentFilter.validate(trimmed)
        return trimmed
    }
}
