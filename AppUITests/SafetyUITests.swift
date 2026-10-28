import XCTest

/// Reporting, blocking and the safety pages (phase 4E), in the demo.
final class SafetyUITests: UITestCase {
    @MainActor
    func testReportingARequest() {
        launchApp()
        let eggs = row("nearby.row.", containing: "Need 2 eggs for a cake")
        XCTAssertTrue(eggs.waitForExistence(timeout: Self.waitTimeout))
        eggs.tap()

        app.buttons["detail.more"].tap()
        app.buttons["detail.report"].tap()
        let spam = app.buttons["report.reason.spam"]
        XCTAssertTrue(spam.waitForExistence(timeout: Self.waitTimeout))
        XCTAssertFalse(app.buttons["report.send"].isEnabled)
        spam.tap()
        app.buttons["report.send"].tap()

        XCTAssertTrue(element("report.sent").waitForExistence(timeout: Self.waitTimeout))
        app.buttons["report.done"].tap()
        XCTAssertTrue(element("detail.title").waitForExistence(timeout: Self.waitTimeout))
    }

    @MainActor
    func testBlockingSomeoneHidesTheirRequestsUntilUnblocked() {
        launchApp()
        let eggs = row("nearby.row.", containing: "Need 2 eggs for a cake")
        XCTAssertTrue(eggs.waitForExistence(timeout: Self.waitTimeout))
        eggs.tap()
        scrollToAndTap(element("detail.requester"))
        waitFor(element("profile.name"), toRead: "Chen")

        app.buttons["profile.more"].tap()
        app.buttons["profile.block"].tap()
        // The confirmation can draw its button twice (sheet and popover layers), so take the first.
        let confirm = app.buttons["profile.confirmBlock"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: Self.waitTimeout))
        confirm.tap()

        // Blocking closes the profile; back on Nearby, Chen's request is gone.
        XCTAssertTrue(element("detail.title").waitForExistence(timeout: Self.waitTimeout))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(element("nearby.count").waitForExistence(timeout: Self.waitTimeout))
        XCTAssertTrue(eggs.waitForNonExistence(timeout: Self.waitTimeout))

        openTab("Profile")
        scrollToAndTap(app.buttons["profile.blockedPeople"])
        let unblock = app.buttons["blocked.unblock.user-chen"]
        XCTAssertTrue(unblock.waitForExistence(timeout: Self.waitTimeout))
        unblock.tap()
        XCTAssertTrue(element("blocked.empty").waitForExistence(timeout: Self.waitTimeout))

        openTab("Nearby")
        app.swipeDown()
        XCTAssertTrue(eggs.waitForExistence(timeout: Self.waitTimeout))
    }

    @MainActor
    func testSafetyTipsOpenFromTheProfile() {
        launchApp()
        openTab("Profile")
        scrollToAndTap(app.buttons["profile.safetyTips"])
        XCTAssertTrue(app.navigationBars["Safety tips"].waitForExistence(timeout: Self.waitTimeout))
    }
}
