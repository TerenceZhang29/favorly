import XCTest

/// Captures the App Store screenshots: eight screens, in light mode, as Alex on Roosevelt Island with demo data.
/// Skipped unless a destination folder is given. `-noDevSettings` hides the Debug-only Dev Settings tab, as in the
/// App Store build, `-hideStatusBar` hides the status bar, and `-demoReplies` has Bea answer Alex's message, for the
/// banner and the Messages tab. Run by `scripts/make-store-screenshots.sh`.
final class AppStoreScreenshotUITests: UITestCase {
    @MainActor private var folder = ""

    @MainActor
    func testCaptureAppStoreScreenshots() throws {
        guard let folder = ProcessInfo.processInfo.environment["STORE_SCREENSHOT_DIR"] else {
            throw XCTSkip("Set TEST_RUNNER_STORE_SCREENSHOT_DIR to capture the App Store screenshots.")
        }
        self.folder = folder
        XCUIDevice.shared.appearance = .light
        let storeLook = ["-noDevSettings", "-hideStatusBar", "-demoReplies", "-AppleLocale", "en_US"]
        app.launchArguments = ["-uiTesting"] + storeLook + Self.freshDefaults
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
        // Leave and reopen the chat: it opens without the keyboard, which some simulators won't drag away.
        goBack()
        scrollToAndTap(app.buttons["detail.message"])
        XCTAssertTrue(element("chat.input").waitForExistence(timeout: Self.waitTimeout))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        try capture("4-chat")
        goBack()

        // 5. Bea answers while Alex is on the request: the banner, and 6. her reply on the Messages tab.
        try captureMessages()

        // 7. The requester's profile: Kindness score and reviews.
        scrollToAndTap(element("detail.requester"))
        waitFor(element("profile.name"), toRead: "Bea")
        try capture("7-profile")
        goBack()

        // 8. Asking for a favor.
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
        try capture("8-post")
    }

    @MainActor
    private func captureMessages() throws {
        XCTAssertTrue(element("banner").waitForExistence(timeout: Self.waitTimeout))
        // Let the banner finish sliding in.
        Thread.sleep(forTimeInterval: 1.5)
        try capture("5-message-banner")
        app.buttons["banner.later"].tap()
        XCTAssertTrue(element("banner").waitForNonExistence(timeout: Self.waitTimeout))
        openTab("Messages")
        XCTAssertTrue(row("inbox.row.", containing: "1 unread").waitForExistence(timeout: Self.waitTimeout))
        try capture("6-messages")
        openTab("Nearby")
    }

    /// Drags the content down, which closes the keyboard on scroll views that dismiss it interactively. A slow
    /// simulator can miss a drag, so it tries a few times.
    @MainActor
    private func dragKeyboardAway() {
        let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        let bottom = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        for _ in 0 ..< 3 {
            top.press(forDuration: 0.1, thenDragTo: bottom)
            if app.keyboards.firstMatch.waitForNonExistence(timeout: 3) {
                return
            }
        }
    }

    @MainActor
    private func capture(_ name: String) throws {
        let file = URL(fileURLWithPath: folder).appendingPathComponent("\(name).png")
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: file)
    }
}
