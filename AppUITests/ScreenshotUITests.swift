import XCTest

/// Captures every screen in light mode, dark mode, at a large accessibility text size and at the largest one. Skipped
/// unless a destination
/// folder is given:
/// `TEST_RUNNER_SCREENSHOT_DIR=/some/folder xcodebuild test ... -only-testing:FavorlyUITests/ScreenshotUITests`
final class ScreenshotUITests: UITestCase {
    @MainActor private var folder = ""
    @MainActor private var suffix = ""
    private static let shortWait: TimeInterval = 2
    private static let maxSwipes = 4

    override func tearDown() {
        MainActor.assumeIsolated {
            XCUIDevice.shared.appearance = .light
        }
        super.tearDown()
    }

    @MainActor
    func testCaptureScreenshotsInLightMode() throws {
        try captureScreens(appearance: .light, suffix: "light")
    }

    @MainActor
    func testCaptureScreenshotsInDarkMode() throws {
        try captureScreens(appearance: .dark, suffix: "dark")
    }

    @MainActor
    func testCaptureScreenshotsAtAccessibilityLargeText() throws {
        try captureScreens(
            appearance: .light,
            suffix: "accessibility-large",
            extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]
        )
    }

    @MainActor
    func testCaptureScreenshotsAtLargestText() throws {
        try captureScreens(
            appearance: .light,
            suffix: "accessibility-largest",
            extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        )
    }

    /// Walks the demo script and writes `<screen>-<suffix>.png` for every screen and its main states.
    @MainActor
    private func captureScreens(
        appearance: XCUIDevice.Appearance,
        suffix: String,
        extraArguments: [String] = []
    ) throws {
        guard let folder = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else {
            throw XCTSkip("Set TEST_RUNNER_SCREENSHOT_DIR to capture screenshots.")
        }
        self.folder = folder
        self.suffix = suffix
        XCUIDevice.shared.appearance = appearance
        app.launchArguments = ["-uiTesting"] + extraArguments
        app.launch()

        try alexPostsARequest()
        try beaPicksItUp()
        try alexSeesItClaimed()
        try farAwayAndLocationError()
        try danaReviewsBea()
    }

    @MainActor
    private func alexPostsARequest() throws {
        waitFor(element("nearby.count"), toRead: "7 requests")
        try capture("nearby")

        openTab("My Activity")
        waitFor(element("activity.empty"), toRead: "You haven't posted any requests yet.")
        try capture("my-activity-empty")

        openTab("Profile")
        waitFor(element("profile.name"), toRead: "Alex")
        try capture("profile-empty")

        openTab("Post")
        // At the largest text size the location row is below the fold, so it is given a moment but not required.
        XCTAssertTrue(app.textFields["post.title"].waitForExistence(timeout: Self.waitTimeout))
        _ = element("post.location").waitForExistence(timeout: Self.shortWait)
        try capture("post-empty")
        app.textFields["post.title"].tap()
        app.typeText("Ne")
        waitFor(element("post.titleMessage"), toRead: "Title must be at least 3 characters.")
        try capture("post-invalid")
        app.typeText("ed a cup of rice\n")
        app.buttons["post.category"].tap()
        if !app.buttons["Ingredient"].waitForExistence(timeout: Self.shortWait) {
            // The first tap can land while the keyboard is still closing.
            app.buttons["post.category"].tap()
        }
        app.buttons["Ingredient"].tap()
        try capture("post")
        scrollToAndTap(app.buttons["post.submit"])
        XCTAssertTrue(row("activity.row.", containing: "Need a cup of rice")
            .waitForExistence(timeout: Self.waitTimeout))
        try capture("my-activity-new")
    }

    @MainActor
    private func beaPicksItUp() throws {
        chooseUser("user-bea")
        try capture("dev-settings")
        openTab("Nearby")
        XCTAssertTrue(element("nearby.count").waitForExistence(timeout: Self.waitTimeout))
        let ownRow = row("nearby.row.", containing: "yours")
        for _ in 0 ..< Self.maxSwipes where !ownRow.waitForExistence(timeout: Self.shortWait) {
            app.swipeUp()
        }
        XCTAssertTrue(ownRow.exists)
        try capture("nearby-yours")
        row("nearby.row.", containing: "Need a cup of rice").tap()
        waitFor(element("detail.title"), toRead: "Need a cup of rice")
        try capture("request-detail-open")
        scrollToAndTap(app.buttons["detail.pickUp"])
        app.buttons["Confirm pick up"].tap()
        // The helper's auto-complete note can be below the fold at the largest text size, so it is given a moment
        // but not required.
        _ = element("detail.autoCompleteNote").waitForExistence(timeout: Self.shortWait)
        try capture("request-detail")
        scrollToAndTap(app.buttons["detail.message"])
        XCTAssertTrue(element("chat.input").waitForExistence(timeout: Self.waitTimeout))
        try capture("chat-empty")
        element("chat.input").tap()
        app.typeText("On my way")
        app.buttons["chat.send"].tap()
        _ = element("chat.empty").waitForNonExistence(timeout: Self.waitTimeout)
        try capture("chat")
        app.navigationBars.buttons.firstMatch.tap()

        openTab("My Activity")
        app.segmentedControls["activity.segment"].buttons["Picked up by me"].tap()
        XCTAssertTrue(row("activity.row.", containing: "Posted by Alex").waitForExistence(timeout: Self.waitTimeout))
        try capture("my-activity-picked-up")
        app.segmentedControls["activity.segment"].buttons["My requests"].tap()

        openTab("Profile")
        waitFor(element("profile.name"), toRead: "Bea")
        try capture("profile")
    }

    @MainActor
    private func alexSeesItClaimed() throws {
        chooseUser("user-alex")
        openTab("Nearby")
        // Wait for something at the top: at large text sizes the buttons below the fold do not exist yet.
        XCTAssertTrue(app.navigationBars["Request"].waitForExistence(timeout: Self.waitTimeout))
        try capture("request-detail-own")
        scrollToAndTap(element("detail.helper"))
        waitFor(element("profile.name"), toRead: "Bea")
        try capture("profile-other")
        app.navigationBars.buttons.firstMatch.tap()
        openTab("My Activity")
        XCTAssertTrue(row("activity.row.", containing: "Claimed by Bea").waitForExistence(timeout: Self.waitTimeout))
        try capture("my-activity")
    }

    @MainActor
    private func farAwayAndLocationError() throws {
        openTab("Dev Settings")
        scrollToAndTap(app.buttons["devSettings.location.ithaca"])
        openTab("Nearby")
        app.navigationBars.buttons.firstMatch.tap()
        waitFor(element("nearby.empty"), toRead: "No requests within 1 mi")
        try capture("nearby-empty")

        openTab("Dev Settings")
        scrollToAndTap(app.switches["devSettings.simulateLocationError"].switches.firstMatch)
        openTab("Nearby")
        waitFor(element("nearby.error"), toRead: "Your location isn't available right now.")
        try capture("nearby-error")

        openTab("Dev Settings")
        app.swipeUp()
        try capture("dev-settings-bottom")
    }

    @MainActor
    private func danaReviewsBea() throws {
        chooseUser("user-dana")
        openTab("My Activity")
        let saffron = row("activity.row.", containing: "Need a pinch of saffron")
        XCTAssertTrue(saffron.waitForExistence(timeout: Self.waitTimeout))
        saffron.tap()
        scrollToAndTap(app.buttons["detail.review"])
        XCTAssertTrue(app.buttons["review.star.5"].waitForExistence(timeout: Self.waitTimeout))
        try capture("review-form-empty")
        app.buttons["review.star.5"].tap()
        element("review.comment").tap()
        app.typeText("Fast and friendly")
        try capture("review-form")
        app.buttons["review.submit"].tap()
        XCTAssertTrue(element("detail.reviewSummary").waitForExistence(timeout: Self.waitTimeout))
        try capture("request-detail-reviewed")
        scrollToAndTap(element("detail.helper"))
        waitFor(element("profile.name"), toRead: "Bea")
        app.swipeUp()
        try capture("profile-reviews")
    }

    /// Switches user from Dev Settings. At the largest text size the row can be off screen in either direction.
    @MainActor
    private func chooseUser(_ id: String) {
        openTab("Dev Settings")
        let button = app.buttons["devSettings.user.\(id)"]
        for _ in 0 ..< Self.maxSwipes where !(button.exists && button.isHittable) {
            app.swipeDown()
        }
        scrollToAndTap(button)
    }

    @MainActor
    private func capture(_ name: String) throws {
        let file = URL(fileURLWithPath: folder).appendingPathComponent("\(name)-\(suffix).png")
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: file)
    }
}
