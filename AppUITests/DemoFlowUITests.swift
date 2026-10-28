import XCTest

/// The demo script in docs/PLAN.md, which is Flow 1 end to end: Alex posts, Bea picks up, Alex sees the claim.
/// `testExtendedDemoScript` runs the Phase 3 script: profiles, chat, a review and a gift card.
final class DemoFlowUITests: UITestCase {
    @MainActor private var count: XCUIElement { element("nearby.count") }

    @MainActor
    func testDemoScript() {
        launchApp()
        browseNearbyAsAlex()
        postARequestAsAlex()
        pickItUpAsBea()
        completeItAsAlex()
        moveFarAwayAndReset()
    }

    /// Steps 1 and 2: Dev Settings shows who is signed in, and the radius changes the Nearby list.
    @MainActor
    private func browseNearbyAsAlex() {
        openTab("Dev Settings")
        waitFor(element("devSettings.summary"), toRead: "Alex @ Cornell Tech, Roosevelt Island")

        openTab("Nearby")
        let radius = app.segmentedControls["nearby.radiusPicker"]
        waitFor(count, toRead: "7 requests")
        radius.buttons["0.25 mi"].tap()
        waitFor(count, toRead: "3 requests")
        radius.buttons["3 mi"].tap()
        waitFor(count, toRead: "8 requests")
        radius.buttons["1 mi"].tap()
        waitFor(count, toRead: "7 requests")
    }

    /// Step 3: Alex posts, and My Activity shows the request as open.
    @MainActor
    private func postARequestAsAlex() {
        openTab("Post")
        waitFor(element("post.location"), toRead: "Tagged at Cornell Tech, Roosevelt Island")
        XCTAssertFalse(app.buttons["post.submit"].isEnabled)
        app.textFields["post.title"].tap()
        app.typeText("ab")
        waitFor(element("post.titleMessage"), toRead: "Title must be at least 3 characters.")
        XCTAssertFalse(app.buttons["post.submit"].isEnabled)
        app.typeText("\u{8}\u{8}Need a cup of rice\n")
        app.buttons["post.category"].tap()
        app.buttons["Ingredient"].tap()
        app.buttons["post.submit"].tap()

        let postedRow = row("activity.row.", containing: "Need a cup of rice")
        XCTAssertTrue(postedRow.waitForExistence(timeout: Self.waitTimeout))
        XCTAssertTrue(app.tabBars.buttons["My Activity"].isSelected)
        XCTAssertEqual(postedRow.label, "Need a cup of rice, Ingredient, Open, new")
    }

    /// Steps 4 and 5: Bea sees the request at the top of Nearby and picks it up.
    /// It leaves Nearby and appears under Picked up by me.
    @MainActor
    private func pickItUpAsBea() {
        switchUser(to: "user-bea")
        openTab("Nearby")
        waitFor(count, toRead: "8 requests")
        let nearbyRow = row("nearby.row.", containing: "Need a cup of rice")
        XCTAssertTrue(nearbyRow.label.contains("less than 0.1 miles away"))
        XCTAssertTrue(nearbyRow.label.hasSuffix("by Alex"))

        nearbyRow.tap()
        app.buttons["detail.pickUp"].tap()
        app.buttons["Confirm pick up"].tap()
        waitFor(element("detail.status"), toRead: "Claimed by Bea")
        app.navigationBars.buttons.firstMatch.tap()
        waitFor(count, toRead: "7 requests")
        XCTAssertFalse(row("nearby.row.", containing: "Need a cup of rice").exists)

        openTab("My Activity")
        app.segmentedControls["activity.segment"].buttons["Picked up by me"].tap()
        let pickedUpRow = row("activity.row.", containing: "Need a cup of rice")
        XCTAssertTrue(pickedUpRow.waitForExistence(timeout: Self.waitTimeout))
        XCTAssertTrue(pickedUpRow.label.hasSuffix("Claimed by Bea, Posted by Alex"))
    }

    /// Step 6: Alex sees who claimed it and marks it completed.
    @MainActor
    private func completeItAsAlex() {
        switchUser(to: "user-alex")
        openTab("My Activity")
        app.segmentedControls["activity.segment"].buttons["My requests"].tap()
        let claimedRow = row("activity.row.", containing: "Claimed by Bea")
        XCTAssertTrue(claimedRow.waitForExistence(timeout: Self.waitTimeout))
        claimedRow.tap()
        waitFor(element("detail.status"), toRead: "Claimed by Bea")
        app.buttons["detail.complete"].tap()
        waitFor(element("detail.status"), toRead: "Completed")
        app.navigationBars.buttons.firstMatch.tap()
    }

    /// Step 7: from Ithaca nothing is nearby, and resetting clears what the demo created.
    @MainActor
    private func moveFarAwayAndReset() {
        openTab("Dev Settings")
        app.buttons["devSettings.location.ithaca"].tap()
        openTab("Nearby")
        waitFor(element("nearby.empty"), toRead: "No requests within 1 mi")

        openTab("Dev Settings")
        let reset = app.buttons["devSettings.resetDemoData"]
        if !reset.isHittable {
            app.swipeUp()
        }
        reset.tap()
        openTab("My Activity")
        waitFor(element("activity.empty"), toRead: "You haven't posted any requests yet.")
    }

    // MARK: Phase 3 extended demo script (docs/PLAN-PHASE-3.md)

    @MainActor
    func testExtendedDemoScript() {
        launchApp()
        alexStartsAtZero()
        alexPostsAndBeaHas90()
        beaPicksUpAndTheyChat()
        alexReviewsBea()
        beaSeesHerNewScore()
        chenSeesBeasPublicProfile()
    }

    /// Step 1: Alex's Profile shows a score of 0 and "No activity yet".
    @MainActor
    private func alexStartsAtZero() {
        openTab("Profile")
        waitFor(element("profile.name"), toRead: "Alex")
        waitFor(element("profile.score"), toRead: "0 points")
        let empty = element("profile.empty")
        for _ in 0 ..< 4 where !(empty.exists && empty.isHittable) {
            app.swipeUp()
        }
        waitFor(empty, toRead: "No activity yet")
    }

    /// Step 2: Alex posts "Need a cup of rice". Bea's Profile shows 90 points and "90 of 100 points".
    @MainActor
    private func alexPostsAndBeaHas90() {
        openTab("Post")
        waitFor(element("post.location"), toRead: "Tagged at Cornell Tech, Roosevelt Island")
        app.textFields["post.title"].tap()
        app.typeText("Need a cup of rice\n")
        app.buttons["post.category"].tap()
        app.buttons["Ingredient"].tap()
        app.buttons["post.submit"].tap()
        XCTAssertTrue(row("activity.row.", containing: "Need a cup of rice")
            .waitForExistence(timeout: Self.waitTimeout))

        switchUser(to: "user-bea")
        openTab("Profile")
        waitFor(element("profile.name"), toRead: "Bea")
        waitFor(element("profile.score"), toRead: "90 points")
    }

    /// Step 3: Bea picks up the request and says "On my way"; Alex replies and marks it completed.
    @MainActor
    private func beaPicksUpAndTheyChat() {
        openTab("Nearby")
        let rice = row("nearby.row.", containing: "Need a cup of rice")
        XCTAssertTrue(rice.waitForExistence(timeout: Self.waitTimeout))
        rice.tap()
        app.buttons["detail.pickUp"].tap()
        app.buttons["Confirm pick up"].tap()
        waitFor(element("detail.status"), toRead: "Claimed by Bea")
        scrollToAndTap(app.buttons["detail.message"])
        sendChatMessage("On my way")
        XCTAssertTrue(chatBubble(containing: "You said: On my way").waitForExistence(timeout: Self.waitTimeout))
        app.navigationBars.buttons.firstMatch.tap()
        app.navigationBars.buttons.firstMatch.tap()

        switchUser(to: "user-alex")
        openTab("My Activity")
        app.segmentedControls["activity.segment"].buttons["My requests"].tap()
        let claimed = row("activity.row.", containing: "Claimed by Bea")
        XCTAssertTrue(claimed.waitForExistence(timeout: Self.waitTimeout))
        claimed.tap()
        scrollToAndTap(app.buttons["detail.message"])
        XCTAssertTrue(chatBubble(containing: "Bea said: On my way").waitForExistence(timeout: Self.waitTimeout))
        sendChatMessage("Thank you!")
        XCTAssertTrue(chatBubble(containing: "You said: Thank you!").waitForExistence(timeout: Self.waitTimeout))
        app.navigationBars.buttons.firstMatch.tap()
        scrollToAndTap(app.buttons["detail.complete"])
        waitFor(element("detail.status"), toRead: "Completed")
    }

    /// Step 4: Alex leaves Bea a 5-star review, "Fast and friendly".
    @MainActor
    private func alexReviewsBea() {
        scrollToAndTap(app.buttons["detail.review"])
        XCTAssertTrue(app.buttons["review.star.5"].waitForExistence(timeout: Self.waitTimeout))
        app.buttons["review.star.5"].tap()
        element("review.comment").tap()
        app.typeText("Fast and friendly")
        app.buttons["review.submit"].tap()
        XCTAssertTrue(element("detail.reviewSummary").waitForExistence(timeout: Self.waitTimeout))
        app.navigationBars.buttons.firstMatch.tap()
    }

    /// Step 5: Bea has 110 points, the new review and the favor.
    @MainActor
    private func beaSeesHerNewScore() {
        switchUser(to: "user-bea")
        openTab("Profile")
        waitFor(element("profile.score"), toRead: "110 points")

        let favor = row("profile.activity.", containing: "Need a cup of rice, Ingredient, Helped")
        for _ in 0 ..< 4 where !(favor.exists && favor.isHittable) {
            app.swipeUp()
        }
        XCTAssertTrue(favor.exists)
        let review = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "profile.review.", "from Alex"
        )).firstMatch
        for _ in 0 ..< 6 where !(review.exists && review.isHittable) {
            app.swipeUp()
        }
        XCTAssertTrue(review.label.hasSuffix(": Fast and friendly"))
    }

    /// Step 6: Chen opens Bea's profile from a request: score and reviews, no account section.
    @MainActor
    private func chenSeesBeasPublicProfile() {
        switchUser(to: "user-chen")
        openTab("My Activity")
        app.segmentedControls["activity.segment"].buttons["My requests"].tap()
        let plants = row("activity.row.", containing: "Water my plants")
        for _ in 0 ..< 4 where !(plants.exists && plants.isHittable) {
            app.swipeUp()
        }
        plants.tap()
        scrollToAndTap(element("detail.helper"))
        waitFor(element("profile.name"), toRead: "Bea")
        waitFor(element("profile.score"), toRead: "110 points")
        XCTAssertFalse(app.buttons["profile.signOut"].exists)
        let review = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "profile.review.", "from Alex"
        )).firstMatch
        for _ in 0 ..< 6 where !(review.exists && review.isHittable) {
            app.swipeUp()
        }
        XCTAssertTrue(review.exists)
    }

    @MainActor
    private func sendChatMessage(_ text: String) {
        let input = element("chat.input")
        XCTAssertTrue(input.waitForExistence(timeout: Self.waitTimeout))
        input.tap()
        app.typeText(text)
        app.buttons["chat.send"].tap()
    }

    @MainActor
    private func chatBubble(containing text: String) -> XCUIElement {
        let matches = NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "chat.message.", text)
        return app.descendants(matching: .any).matching(matches).firstMatch
    }

    @MainActor
    func testMyActivityIsEmptyForAlexAtLaunch() {
        launchApp()
        openTab("My Activity")
        waitFor(element("activity.empty"), toRead: "You haven't posted any requests yet.")
        app.segmentedControls["activity.segment"].buttons["Picked up by me"].tap()
        waitFor(element("activity.empty"), toRead: "You haven't picked up any requests yet.")
    }
}
