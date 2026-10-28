import FavorlyCore
import Foundation
import Testing

struct ContentFilterTests {
    @Test(arguments: ["Fuck this", "what the SHIT", "you're a b-i-t-c-h? no: bitch.", "what shits", "dicks"])
    func offensiveWordsAreCaught(text: String) {
        #expect(ContentFilter.containsOffensiveWord(text))
    }

    @Test(arguments: [
        "Need a cup of rice", "Scunthorpe", "Dickens novels", "Hold a ladder", "", "Cocktail glasses",
        "Shiitake mushrooms", "Bass guitar",
    ])
    func ordinaryTextPasses(text: String) {
        #expect(!ContentFilter.containsOffensiveWord(text))
    }

    @Test func validateThrowsTheMessage() {
        #expect(throws: FavorlyError.validation("Please remove offensive language.")) {
            try ContentFilter.validate("shit")
        }
    }

    @Test func everyValidatorUsesTheFilter() {
        let here = TaggedLocation(point: GeoPoint(latitude: 40.755, longitude: -73.956), label: "Here")
        let refused = FavorlyError.validation(ContentFilter.message)
        #expect(throws: refused) {
            try DraftValidator.validate(NewRequestDraft(title: "Need shit", details: "", category: .other, location: here))
        }
        #expect(throws: refused) {
            try DraftValidator.validate(NewRequestDraft(title: "Need rice", details: "fuck", category: .other, location: here))
        }
        #expect(throws: refused) { try ChatRules.validateText("bitch") }
        #expect(throws: refused) { try ReviewRules.validate(NewReviewDraft(rating: 1, comment: "asshole")) }
        #expect(throws: refused) {
            try ProfileSetupRules.validate(ProfileSetupDraft(displayName: "Dick", confirmedAdult: true, acceptedTerms: true))
        }
    }

    /// The server's copy in the safety migration must list exactly the same words.
    @Test func theServerHasTheSameList() throws {
        let migration = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "backend/supabase/migrations/20261029000006_safety.sql")
        let sql = try String(contentsOf: migration, encoding: .utf8)
        let list = try #require(sql.range(of: "array[")).upperBound
        let end = try #require(sql[list...].range(of: "]")).lowerBound
        let words = sql[list ..< end].split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "'"))
        }
        #expect(Set(words) == ContentFilter.words)
    }
}
