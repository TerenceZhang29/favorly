import XCTest

/// Welcome, profile setup, sign out and account deletion (phase 4A), against the mock sign-in.
final class OnboardingUITests: UITestCase {
    @MainActor
    private func launchSignedOut() {
        app.launchArguments = ["-uiTesting", "-signedOut"]
        app.launch()
    }

    /// From Welcome to the tabs as a new user called Sam.
    @MainActor
    private func signUpAsSam() {
        let signIn = app.buttons["welcome.signIn"]
        XCTAssertTrue(signIn.waitForExistence(timeout: Self.waitTimeout))
        signIn.tap()

        let name = app.textFields["setup.name"]
        XCTAssertTrue(name.waitForExistence(timeout: Self.waitTimeout))
        let continueButton = app.buttons["setup.continue"]
        XCTAssertFalse(continueButton.isEnabled)

        name.tap()
        name.typeText("Sam\n")
        app.switches["setup.adult"].switches.firstMatch.tap()
        XCTAssertFalse(continueButton.isEnabled)
        app.switches["setup.terms"].switches.firstMatch.tap()
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        XCTAssertTrue(app.tabBars.buttons["Profile"].waitForExistence(timeout: Self.waitTimeout))
    }

    @MainActor
    func testANewUserSignsUpAndSeesTheirProfile() {
        launchSignedOut()
        signUpAsSam()
        openTab("Profile")
        waitFor(element("profile.name"), toRead: "Sam")
        waitFor(element("profile.score"), toRead: "0 points")
    }

    @MainActor
    func testCancellingSetupReturnsToWelcome() {
        launchSignedOut()
        app.buttons["welcome.signIn"].tap()
        let cancel = app.buttons["setup.cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: Self.waitTimeout))
        cancel.tap()
        XCTAssertTrue(app.buttons["welcome.signIn"].waitForExistence(timeout: Self.waitTimeout))
    }

    @MainActor
    func testSigningOutReturnsToWelcome() {
        launchApp()
        openTab("Profile")
        scrollToAndTap(app.buttons["profile.signOut"])
        XCTAssertTrue(app.buttons["welcome.signIn"].waitForExistence(timeout: Self.waitTimeout))
    }

    @MainActor
    func testDeletingTheAccountAsksFirstThenReturnsToWelcome() {
        launchSignedOut()
        signUpAsSam()
        openTab("Profile")
        waitFor(element("profile.name"), toRead: "Sam")
        scrollToAndTap(app.buttons["profile.deleteAccount"])

        // The confirmation can draw its button twice (sheet and popover layers), so take the first.
        let confirm = app.buttons["profile.confirmDelete"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: Self.waitTimeout))
        confirm.tap()
        XCTAssertTrue(app.buttons["welcome.signIn"].waitForExistence(timeout: Self.waitTimeout))
    }
}
