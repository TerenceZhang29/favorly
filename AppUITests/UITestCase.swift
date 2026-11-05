import XCTest

/// Shared launch and lookup helpers. Each test launches the app fresh with no mock delay.
class UITestCase: XCTestCase {
    /// Generous, because hosted CI machines are several times slower than a laptop.
    static let waitTimeout: TimeInterval = 20

    /// Hides the neighborhood an earlier test posted with (Post offers it first), so each test starts the same.
    static let freshDefaults = ["-lastNeighborhood", ""]

    @MainActor lazy var app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func launchApp() {
        app.launchArguments = ["-uiTesting"] + Self.freshDefaults
        app.launch()
    }

    /// Finds an element by accessibility identifier, whatever kind of element it is.
    @MainActor
    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    /// Finds a list row by identifier prefix and part of its spoken label.
    @MainActor
    func row(_ prefix: String, containing text: String) -> XCUIElement {
        let matches = NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", prefix, text)
        return app.buttons.matching(matches).firstMatch
    }

    @MainActor
    func openTab(_ title: String) {
        // A slow simulator (GitHub's) can drop a tab tap, so tap again until the tab is selected.
        let tab = app.tabBars.buttons[title]
        let selected = NSPredicate(format: "isSelected == true")
        for _ in 0 ..< 3 {
            tab.tap()
            let opened = XCTNSPredicateExpectation(predicate: selected, object: tab)
            if XCTWaiter().wait(for: [opened], timeout: 5) == .completed {
                return
            }
        }
        XCTAssertTrue(tab.isSelected, "The \(title) tab didn't open")
    }

    @MainActor
    func switchUser(to id: String) {
        openTab("Dev Settings")
        let user = app.buttons["devSettings.user.\(id)"]
        // Right after launch a slow simulator can still be drawing the tab.
        XCTAssertTrue(user.waitForExistence(timeout: Self.waitTimeout))
        user.tap()
    }

    /// Scrolls up until the element is on screen, for lists that grow at large text sizes, then taps it.
    @MainActor
    func scrollToAndTap(_ element: XCUIElement) {
        for _ in 0 ..< 4 where !(element.exists && element.isHittable) {
            app.swipeUp()
        }
        element.tap()
    }

    /// Waits until an element with the same identifier reads `text` as its label or value.
    /// A SwiftUI `Label` can expose its icon and its text under one identifier, so every match is considered.
    @MainActor
    func waitFor(_ element: XCUIElement, toRead text: String, file: StaticString = #filePath, line: UInt = #line) {
        guard element.waitForExistence(timeout: Self.waitTimeout) else {
            return XCTFail("Expected \"\(text)\", found nothing", file: file, line: line)
        }
        let matches = NSPredicate(
            format: "identifier == %@ AND (label == %@ OR value == %@)", element.identifier, text, text
        )
        let reading = app.descendants(matching: .any).matching(matches).firstMatch
        let found = reading.waitForExistence(timeout: Self.waitTimeout)
        XCTAssertTrue(found, "Expected \"\(text)\", found \"\(element.label)\"", file: file, line: line)
    }
}
