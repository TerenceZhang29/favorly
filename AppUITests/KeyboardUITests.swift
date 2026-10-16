import XCTest

/// The keyboard can be put away without typing anything, from the keyboard itself.
final class KeyboardUITests: UITestCase {
    @MainActor
    func testDoneKeyClosesTheKeyboardOnPost() {
        launchApp()
        openTab("Post")
        let keyboard = app.keyboards.firstMatch

        element("post.title").tap()
        XCTAssertTrue(keyboard.waitForExistence(timeout: Self.waitTimeout))
        keyboard.buttons["Done"].tap()
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: Self.waitTimeout))

        // The multi-line field would start a new line without the Done key.
        element("post.details").tap()
        XCTAssertTrue(keyboard.waitForExistence(timeout: Self.waitTimeout))
        keyboard.buttons["Done"].tap()
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: Self.waitTimeout))
        // Done left no line break behind.
        XCTAssertEqual(element("post.details").value as? String, "")
    }
}
