@testable import FavorlyFeatures
import Testing

struct DoneKeyModifierTests {
    @Test func aTypedLineBreakIsTheReturnKey() {
        #expect(DoneKeyModifier.isReturnKey(old: "Two eggs", new: "Two eggs\n"))
        #expect(DoneKeyModifier.isReturnKey(old: "Two eggs", new: "Two\n eggs"))
        #expect(DoneKeyModifier.isReturnKey(old: "", new: "\n"))
    }

    @Test func typingADifferentCharacterIsNot() {
        #expect(!DoneKeyModifier.isReturnKey(old: "Two eggs", new: "Two eggs!"))
        #expect(!DoneKeyModifier.isReturnKey(old: "One\nTwo", new: "One\nTwo!"))
    }

    @Test func pastedTextKeepsItsLineBreaks() {
        #expect(!DoneKeyModifier.isReturnKey(old: "", new: "One\nTwo"))
        #expect(!DoneKeyModifier.isReturnKey(old: "One", new: "One\nTwo\nThree"))
    }

    @Test func deletingIsNot() {
        #expect(!DoneKeyModifier.isReturnKey(old: "One\n", new: "One"))
    }
}
