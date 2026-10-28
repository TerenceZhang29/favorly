import XCTest

/// The Profile tab and other users' profiles (Phase 3B).
final class ProfileUITests: UITestCase {
    @MainActor
    func testAlexStartsWithAnEmptyProfile() {
        launchApp()
        openTab("Profile")
        waitFor(element("profile.name"), toRead: "Alex")
        waitFor(element("profile.score"), toRead: "0 points")
        waitFor(element("profile.giftCardProgress"), toRead: "0 of 100 points")
        XCTAssertFalse(app.buttons["profile.redeem"].isEnabled)
        scrollToShow(element("profile.empty"))
        waitFor(element("profile.empty"), toRead: "No activity yet")
    }

    @MainActor
    func testBeasProfileShowsHerScoreAndHistory() {
        launchApp()
        switchUser(to: "user-bea")
        openTab("Profile")
        waitFor(element("profile.name"), toRead: "Bea")
        waitFor(element("profile.score"), toRead: "90 points")
        waitFor(element("profile.favors"), toRead: "5 favors completed")
        waitFor(element("profile.giftCardProgress"), toRead: "90 of 100 points")
        XCTAssertFalse(app.buttons["profile.redeem"].isEnabled)
        let saffron = row("profile.activity.", containing: "Need a pinch of saffron, Ingredient, Helped")
        scrollToShow(saffron)
        XCTAssertTrue(saffron.exists)
    }

    @MainActor
    func testOneMoreFavorLetsBeaRedeemAGiftCard() {
        launchApp()
        switchUser(to: "user-bea")
        openTab("Nearby")
        let eggs = row("nearby.row.", containing: "Need 2 eggs for a cake")
        XCTAssertTrue(eggs.waitForExistence(timeout: Self.waitTimeout))
        eggs.tap()
        app.buttons["detail.pickUp"].tap()
        app.buttons["Confirm pick up"].tap()

        // Only the requester can mark it completed; the helper sees when it completes on its own.
        XCTAssertTrue(element("detail.autoCompleteNote").waitForExistence(timeout: Self.waitTimeout))
        XCTAssertFalse(app.buttons["detail.complete"].exists)

        switchUser(to: "user-chen")
        openTab("My Activity")
        app.segmentedControls["activity.segment"].buttons["My requests"].tap()
        let picked = row("activity.row.", containing: "Need 2 eggs for a cake")
        XCTAssertTrue(picked.waitForExistence(timeout: Self.waitTimeout))
        picked.tap()
        scrollToAndTap(app.buttons["detail.complete"])
        waitFor(element("detail.status"), toRead: "Completed")

        switchUser(to: "user-bea")
        openTab("Profile")
        waitFor(element("profile.score"), toRead: "100 points")
        waitFor(element("profile.giftCardProgress"), toRead: "100 of 100 points")
        scrollToAndTap(app.buttons["profile.redeem"])
        waitFor(element("profile.rewardCode"), toRead: "FAVORLY-0001")
        waitFor(element("profile.giftCardProgress"), toRead: "0 of 100 points")
        waitFor(element("profile.score"), toRead: "100 points")
    }

    @MainActor
    func testRequesterAndHelperOpenTheirProfilesWithoutTheGiftCard() {
        launchApp()
        switchUser(to: "user-chen")
        openTab("My Activity")
        app.segmentedControls["activity.segment"].buttons["Picked up by me"].tap()
        let ladder = row("activity.row.", containing: "Hold a ladder")
        XCTAssertTrue(ladder.waitForExistence(timeout: Self.waitTimeout))
        ladder.tap()

        let requester = element("detail.requester")
        waitFor(requester, toRead: "Dana")
        XCTAssertTrue(requester.label.contains("Posted by"))
        requester.tap()
        waitFor(element("profile.name"), toRead: "Dana")
        waitFor(element("profile.score"), toRead: "0 points")
        XCTAssertFalse(element("profile.giftCardProgress").exists)
        XCTAssertFalse(app.buttons["profile.redeem"].exists)
        app.navigationBars.buttons.firstMatch.tap()

        let helper = element("detail.helper")
        waitFor(helper, toRead: "Chen")
        helper.tap()
        // Chen's own profile, reached from a request, still shows his gift card.
        waitFor(element("profile.name"), toRead: "Chen")
        waitFor(element("profile.score"), toRead: "18 points")
    }

    /// Swipes up until the element is on screen, for content below the fold.
    @MainActor
    private func scrollToShow(_ element: XCUIElement) {
        for _ in 0 ..< 4 where !(element.exists && element.isHittable) {
            app.swipeUp()
        }
    }
}
