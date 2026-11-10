import XCTest

/// Captures the App Store screenshots: six screens, in light mode, as Alex on Roosevelt Island with demo data.
/// Skipped unless a destination folder is given. `-noDevSettings` hides the Debug-only Dev Settings tab, as in the
/// App Store build, and `-hideStatusBar` hides the status bar. Run by `scripts/make-store-screenshots.sh`.
final class AppStoreScreenshotUITests: UITestCase {
    @MainActor private var folder = ""

    @MainActor
    func testCaptureAppStoreScreenshots() throws {
        guard let folder = ProcessInfo.processInfo.environment["STORE_SCREENSHOT_DIR"] else {
            throw XCTSkip("Set TEST_RUNNER_STORE_SCREENSHOT_DIR to capture the App Store screenshots.")
        }
        self.folder = folder
        XCUIDevice.shared.appearance = .light
        app.launchArguments = ["-uiTesting", "-noDevSettings", "-hideStatusBar", "-AppleLocale", "en_US"] + Self.freshDefaults
        app.launch()

        // 1. Requests from neighbors nearby.
        waitFor(element("nearby.count"), toRead: "7 requests")
        try capture("1-nearby")

        // 2. A neighbor's request, and 3. claiming it.
        let riceRow = row("nearby.row.", containing: "Borrow a cup of rice")
        for _ in 0 ..< 4 where !(riceRow.exists && riceRow.isHittable) {
            app.swipeUp()
        }
        riceRow.tap()
        waitFor(element("detail.title"), toRead: "Borrow a cup of rice")
        try capture("2-request-detail")
        scrollToAndTap(app.buttons["detail.pickUp"])
        XCTAssertTrue(app.buttons["claim.confirm"].waitForExistence(timeout: Self.waitTimeout))
        try capture("3-claim")
        app.buttons["claim.confirm"].tap()

        // 4. Chat with the requester.
        scrollToAndTap(app.buttons["detail.message"])
        XCTAssertTrue(element("chat.input").waitForExistence(timeout: Self.waitTimeout))
        element("chat.input").tap()
        app.typeText("Hi Bea! I have rice. Lobby in 10 minutes?")
        app.buttons["chat.send"].tap()
        _ = element("chat.empty").waitForNonExistence(timeout: Self.waitTimeout)
        dragKeyboardAway()
        try capture("4-chat")
        goBack()

        // 5. The requester's profile: Kindness score and reviews.
        scrollToAndTap(element("detail.requester"))
        waitFor(element("profile.name"), toRead: "Bea")
        try capture("5-profile")
        goBack()

        // 6. Asking for a favor.
        openTab("Post")
        // Details first: return in the title field then closes the keyboard.
        element("post.details").tap()
        app.typeText("Hanging curtains this afternoon. I can bring it back by 5.")
        app.textFields["post.title"].tap()
        app.typeText("Need a ladder for an hour\n")
        if app.keyboards.firstMatch.exists {
            dragKeyboardAway()
        }
        XCTAssertTrue(app.buttons["post.submit"].waitForExistence(timeout: Self.waitTimeout))
        try capture("6-post")
    }

    /// Drags the content down, which closes the keyboard on scroll views that dismiss it interactively.
    @MainActor
    private func dragKeyboardAway() {
        let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        let bottom = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        top.press(forDuration: 0.1, thenDragTo: bottom)
        _ = app.keyboards.firstMatch.waitForNonExistence(timeout: Self.waitTimeout)
    }

    @MainActor
    private func capture(_ name: String) throws {
        let file = URL(fileURLWithPath: folder).appendingPathComponent("\(name).png")
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: file)
    }
}
