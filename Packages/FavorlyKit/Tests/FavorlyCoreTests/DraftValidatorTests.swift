import FavorlyCore
import Testing

struct DraftValidatorTests {
    private func draft(title: String, details: String = "") -> NewRequestDraft {
        NewRequestDraft(
            title: title,
            details: details,
            category: .other,
            location: TaggedLocation(point: GeoPoint(latitude: 40.7553, longitude: -73.9562), label: "Cornell Tech")
        )
    }

    @Test(arguments: [3, 80])
    func titleAtTheLimitsIsValid(length: Int) throws {
        try DraftValidator.validate(draft(title: String(repeating: "a", count: length)))
    }

    @Test(arguments: [0, 2])
    func titleShorterThanThreeCharactersIsRejected(length: Int) {
        #expect(throws: FavorlyError.validation("Title must be at least 3 characters.")) {
            try DraftValidator.validate(draft(title: String(repeating: "a", count: length)))
        }
    }

    @Test func titleLongerThanEightyCharactersIsRejected() {
        #expect(throws: FavorlyError.validation("Title must be 80 characters or fewer.")) {
            try DraftValidator.validate(draft(title: String(repeating: "a", count: 81)))
        }
    }

    @Test(arguments: ["     ", " \n\t ", "  ab  "])
    func whitespaceDoesNotCountTowardTheTitleLength(title: String) {
        #expect(throws: FavorlyError.validation("Title must be at least 3 characters.")) {
            try DraftValidator.validate(draft(title: title))
        }
    }

    @Test func titleAndDetailsAreTrimmed() throws {
        let normalized = try DraftValidator.validate(draft(title: "  Need rice \n", details: "\tOne cup  "))
        #expect(normalized.title == "Need rice")
        #expect(normalized.details == "One cup")
    }

    @Test(arguments: [0, 500])
    func detailsAtTheLimitsAreValid(length: Int) throws {
        try DraftValidator.validate(draft(title: "Need rice", details: String(repeating: "d", count: length)))
    }

    @Test func detailsLongerThanFiveHundredCharactersAreRejected() {
        #expect(throws: FavorlyError.validation("Details must be 500 characters or fewer.")) {
            try DraftValidator.validate(draft(title: "Need rice", details: String(repeating: "d", count: 501)))
        }
    }

    // MARK: Neighborhood

    static let neighborhoods = [
        "Roosevelt Island", "Cornell Tech, Roosevelt Island", "Hell's Kitchen", "Bedford-Stuyvesant",
        "St. George", "Prospect Lefferts Gardens", "Ville-Émard", "  Harlem  ",
    ]

    @Test(arguments: neighborhoods)
    func ordinaryNeighborhoodsPass(label: String) throws {
        #expect(try DraftValidator.validateLocationLabel(label) == label.trimmingCharacters(in: .whitespaces))
    }

    @Test(arguments: ["549 Main St", "Apt 4B", "E 85th St", "near #12", "me@home.com"])
    func addressesAndSymbolsAreRefused(label: String) {
        #expect(throws: FavorlyError.validation("Use only letters for the neighborhood, not a street address.")) {
            try DraftValidator.validateLocationLabel(label)
        }
    }

    @Test func anEmptyOrLongNeighborhoodIsRefused() throws {
        #expect(throws: FavorlyError.validation("Add a neighborhood for your request.")) {
            try DraftValidator.validateLocationLabel("   ")
        }
        #expect(try DraftValidator.validateLocationLabel(String(repeating: "a", count: 40)).count == 40)
        #expect(throws: FavorlyError.validation("Neighborhood must be 40 characters or fewer.")) {
            try DraftValidator.validateLocationLabel(String(repeating: "a", count: 41))
        }
    }

    @Test func anOffensiveNeighborhoodIsRefused() {
        #expect(throws: FavorlyError.validation(ContentFilter.message)) {
            try DraftValidator.validateLocationLabel("Shit Street")
        }
    }

    @Test func theDraftsNeighborhoodIsCheckedAndTrimmed() throws {
        let here = GeoPoint(latitude: 40.755, longitude: -73.956)
        let draft = NewRequestDraft(
            title: "Need rice", details: "", category: .other, location: TaggedLocation(point: here, label: " Harlem ")
        )
        #expect(try DraftValidator.validate(draft).location == TaggedLocation(point: here, label: "Harlem"))
        #expect(throws: FavorlyError.validation("Use only letters for the neighborhood, not a street address.")) {
            try DraftValidator.validate(NewRequestDraft(
                title: "Need rice", details: "", category: .other, location: TaggedLocation(
                    point: here,
                    label: "12 Main"
                )
            ))
        }
    }
}
