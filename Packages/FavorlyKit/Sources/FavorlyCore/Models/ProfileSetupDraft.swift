import Foundation

/// What a new user fills in after signing in for the first time.
public struct ProfileSetupDraft: Sendable {
    public var displayName: String
    /// The user confirmed they are 18 or older.
    public var confirmedAdult: Bool
    /// The user accepted the current Terms of Use and Privacy Policy.
    public var acceptedTerms: Bool

    public init(displayName: String, confirmedAdult: Bool, acceptedTerms: Bool) {
        self.displayName = displayName
        self.confirmedAdult = confirmedAdult
        self.acceptedTerms = acceptedTerms
    }
}
