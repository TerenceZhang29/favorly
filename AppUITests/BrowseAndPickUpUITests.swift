import XCTest

/// Flow 2 from the plan: browse nearby, change the radius, open a request and pick it up.
final class BrowseAndPickUpUITests: UITestCase {
    private let eggsRow = "nearby.row.00000000-0000-0000-0000-000000000001"
    private let riceRow = "nearby.row.00000000-0000-0000-0000-000000000002"

    @MainActor
    func testBeaBrowsesNearbyAndPicksUpARequest() {
        launchApp()
        switchUser(to: "user-bea")
        openTab("Nearby")

        let count = element("nearby.count")
        waitFor(count, toRead: "7 requests")
        XCTAssertTrue(app.buttons[riceRow].label.hasSuffix("yours"))
        XCTAssertFalse(app.buttons[eggsRow].label.hasSuffix("yours"))

        let radius = app.segmentedControls["nearby.radiusPicker"]
        radius.buttons["0.25 mi"].tap()
        waitFor(count, toRead: "3 requests")
        radius.buttons["3 mi"].tap()
        waitFor(count, toRead: "8 requests")

        app.buttons[eggsRow].tap()
        waitFor(element("detail.title"), toRead: "Need 2 eggs for a cake")
        waitFor(element("detail.status"), toRead: "Open")

        app.buttons["detail.pickUp"].tap()
        app.buttons["claim.confirm"].tap()
        waitFor(element("detail.status"), toRead: "Claimed by Bea")
        waitFor(element("detail.helper"), toRead: "Bea")
        XCTAssertFalse(app.buttons["detail.pickUp"].exists)

        goBack()
        waitFor(count, toRead: "7 requests")
        XCTAssertFalse(app.buttons[eggsRow].exists)

        openTab("My Activity")
        app.segmentedControls["activity.segment"].buttons["Claimed by me"].tap()
        XCTAssertTrue(row("activity.row.", containing: "Need 2 eggs for a cake")
            .waitForExistence(timeout: Self.waitTimeout))
    }

    @MainActor
    func testOwnRequestHasNoPickUpButton() {
        launchApp()
        switchUser(to: "user-bea")
        openTab("Nearby")

        XCTAssertTrue(app.buttons[riceRow].waitForExistence(timeout: Self.waitTimeout))
        app.buttons[riceRow].tap()
        waitFor(element("detail.requester"), toRead: "Bea (you)")
        XCTAssertFalse(app.buttons["detail.pickUp"].exists)
        XCTAssertTrue(app.buttons["detail.cancel"].exists)
    }

    @MainActor
    func testFarAwayLocationShowsTheEmptyStateAndLocationErrorOffersRetry() {
        launchApp()

        openTab("Dev Settings")
        app.buttons["devSettings.location.ithaca"].tap()
        openTab("Nearby")
        waitFor(element("nearby.empty"), toRead: "No requests within 1 mi")

        openTab("Dev Settings")
        app.switches["devSettings.simulateLocationError"].switches.firstMatch.tap()
        openTab("Nearby")
        waitFor(element("nearby.error"), toRead: "Your location isn't available right now.")
        XCTAssertTrue(app.buttons["nearby.retry"].exists)
    }
}
