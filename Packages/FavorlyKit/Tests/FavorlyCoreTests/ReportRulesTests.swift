import FavorlyCore
import Testing

struct ReportRulesTests {
    @Test func theNoteIsTrimmedAndLimited() throws {
        #expect(try ReportRules.validateNote("  Looks fake \n") == "Looks fake")
        try ReportRules.validateNote(String(repeating: "a", count: 500))
        #expect(throws: FavorlyError.validation("Note must be 500 characters or fewer.")) {
            try ReportRules.validateNote(String(repeating: "a", count: 501))
        }
    }

    @Test func nobodyReportsOrBlocksThemselves() throws {
        #expect(throws: FavorlyError.notAllowed) {
            try ReportRules.validateNotSelf(.requester, by: .requester)
        }
        try ReportRules.validateNotSelf(.helper, by: .requester)
    }

    @Test func reasonsMatchTheServer() {
        #expect(ReportReason.allCases.map(\.rawValue) == ["spam", "inappropriate", "unsafe", "other"])
    }
}
