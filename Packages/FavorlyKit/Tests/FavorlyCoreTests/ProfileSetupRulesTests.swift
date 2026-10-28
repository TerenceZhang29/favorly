import FavorlyCore
import Testing

struct ProfileSetupRulesTests {
    private func draft(
        name: String = "Alex",
        confirmedAdult: Bool = true,
        acceptedTerms: Bool = true
    ) -> ProfileSetupDraft {
        ProfileSetupDraft(displayName: name, confirmedAdult: confirmedAdult, acceptedTerms: acceptedTerms)
    }

    @Test(arguments: [2, 30])
    func nameAtTheLimitsIsValid(length: Int) throws {
        try ProfileSetupRules.validate(draft(name: String(repeating: "a", count: length)))
    }

    @Test func theNameIsTrimmed() throws {
        #expect(try ProfileSetupRules.validate(draft(name: "  Alex \n")).displayName == "Alex")
    }

    @Test(arguments: ["", "A", "   A   "])
    func aNameShorterThanTwoCharactersIsRejected(name: String) {
        #expect(throws: FavorlyError.validation("Name must be at least 2 characters.")) {
            try ProfileSetupRules.validate(draft(name: name))
        }
    }

    @Test func aNameLongerThanThirtyCharactersIsRejected() {
        #expect(throws: FavorlyError.validation("Name must be 30 characters or fewer.")) {
            try ProfileSetupRules.validate(draft(name: String(repeating: "a", count: 31)))
        }
    }

    @Test func theUserMustConfirmTheyAreAnAdult() {
        #expect(throws: FavorlyError.validation("You must be 18 or older to use Favorly.")) {
            try ProfileSetupRules.validate(draft(confirmedAdult: false))
        }
    }

    @Test func theUserMustAcceptTheTerms() {
        #expect(throws: FavorlyError.validation("Please accept the Terms of Use and Privacy Policy.")) {
            try ProfileSetupRules.validate(draft(acceptedTerms: false))
        }
    }

    @Test func theNameIsCheckedBeforeTheBoxes() {
        #expect(throws: FavorlyError.validation("Name must be at least 2 characters.")) {
            try ProfileSetupRules.validate(draft(name: "", confirmedAdult: false, acceptedTerms: false))
        }
    }
}
