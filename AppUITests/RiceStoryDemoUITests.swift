import XCTest

/// Plays the "out of rice" story from the pitch slide, slowly enough to narrate or screen-record.
/// Alex planned to cook, ran out of rice and the store is closed. Bea down the hall brings a cup,
/// Alex cooks as planned, and Bea earns Kindness points.
/// Skipped unless `FAVORLY_DEMO` is set; `scripts/demo-rice-story.sh` sets it and opens the Simulator.
final class RiceStoryDemoUITests: UITestCase {
    /// Seconds to hold on each beat so viewers can read the screen. `DEMO_PACE` overrides it.
    @MainActor private var pace: TimeInterval = 2

    @MainActor
    func testRiceStory() throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["FAVORLY_DEMO"] != nil else {
            throw XCTSkip("Run scripts/demo-rice-story.sh, or set TEST_RUNNER_FAVORLY_DEMO=1, to play the demo.")
        }
        if let value = environment["DEMO_PACE"].flatMap(TimeInterval.init) {
            pace = value
        }
        launchApp()
        alexIsOutOfRice()
        beaBringsACup()
        alexCooksAsPlanned()
        beaEarnsKindnessPoints()
    }

    /// Beat 1: Alex planned to cook tonight, but the rice ran out and the store is closed. Alex asks nearby.
    @MainActor
    private func alexIsOutOfRice() {
        openTab("Post")
        waitFor(element("post.location"), toRead: "Tagged at Cornell Tech, Roosevelt Island")
        hold()
        app.textFields["post.title"].tap()
        typeSlowly("Need a cup of rice")
        app.typeText("\n")
        element("post.details").tap()
        typeSlowly("Cooking dinner tonight and just ran out. The store is closed. Can anyone spare a cup?")
        dismissKeyboard()
        app.buttons["post.category"].tap()
        app.buttons["Ingredient"].tap()
        hold()
        app.buttons["post.submit"].tap()
        let posted = row("activity.row.", containing: "Need a cup of rice")
        XCTAssertTrue(posted.waitForExistence(timeout: Self.waitTimeout))
        hold(2)
    }

    /// Beat 2: Bea, a neighbor, sees the request at the top of Nearby, picks it up and says she is on her way.
    @MainActor
    private func beaBringsACup() {
        switchUser(to: "user-bea")
        openTab("Nearby")
        let rice = row("nearby.row.", containing: "Need a cup of rice")
        XCTAssertTrue(rice.waitForExistence(timeout: Self.waitTimeout))
        hold(2)
        rice.tap()
        hold(2)
        app.buttons["detail.pickUp"].tap()
        hold()
        app.buttons["Confirm pick up"].tap()
        waitFor(element("detail.status"), toRead: "Claimed by Bea")
        hold()
        scrollToAndTap(app.buttons["detail.message"])
        sendMessage("On my way with a cup of rice!")
        hold(2)
        app.navigationBars.buttons.firstMatch.tap()
        app.navigationBars.buttons.firstMatch.tap()
    }

    /// Beat 3: Alex gets the rice, cooks as planned, marks the favor completed and thanks Bea with a review.
    @MainActor
    private func alexCooksAsPlanned() {
        switchUser(to: "user-alex")
        openTab("My Activity")
        app.segmentedControls["activity.segment"].buttons["My requests"].tap()
        let claimed = row("activity.row.", containing: "Claimed by Bea")
        XCTAssertTrue(claimed.waitForExistence(timeout: Self.waitTimeout))
        hold()
        claimed.tap()
        scrollToAndTap(app.buttons["detail.message"])
        XCTAssertTrue(chatBubble(containing: "Bea said: On my way").waitForExistence(timeout: Self.waitTimeout))
        hold()
        sendMessage("Thank you! Dinner is saved.")
        hold()
        app.navigationBars.buttons.firstMatch.tap()
        scrollToAndTap(app.buttons["detail.complete"])
        waitFor(element("detail.status"), toRead: "Completed")
        hold()
        scrollToAndTap(app.buttons["detail.review"])
        XCTAssertTrue(app.buttons["review.star.5"].waitForExistence(timeout: Self.waitTimeout))
        app.buttons["review.star.5"].tap()
        element("review.comment").tap()
        typeSlowly("Saved my home-cooked dinner!")
        hold()
        app.buttons["review.submit"].tap()
        XCTAssertTrue(element("detail.reviewSummary").waitForExistence(timeout: Self.waitTimeout))
        hold()
        app.navigationBars.buttons.firstMatch.tap()
    }

    /// Beat 4: Bea's Profile shows the Kindness points she earned for the favor and the review.
    @MainActor
    private func beaEarnsKindnessPoints() {
        switchUser(to: "user-bea")
        openTab("Profile")
        waitFor(element("profile.score"), toRead: "110 points")
        hold(3)
    }

    // MARK: Helpers

    @MainActor
    private func hold(_ beats: Double = 1) {
        Thread.sleep(forTimeInterval: pace * beats)
    }

    /// Types a word at a time, so the text visibly appears instead of all at once.
    @MainActor
    private func typeSlowly(_ text: String) {
        let words = text.split(separator: " ")
        for (index, word) in words.enumerated() {
            app.typeText(index == 0 ? String(word) : " \(word)")
            Thread.sleep(forTimeInterval: 0.15)
        }
    }

    /// Puts the keyboard away from a multi-line field, with its Done key when it has one.
    @MainActor
    private func dismissKeyboard() {
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else {
            return
        }
        let done = keyboard.buttons["Done"]
        if done.exists {
            done.tap()
        } else {
            app.swipeDown()
        }
        _ = keyboard.waitForNonExistence(timeout: 2)
    }

    @MainActor
    private func sendMessage(_ text: String) {
        let input = element("chat.input")
        XCTAssertTrue(input.waitForExistence(timeout: Self.waitTimeout))
        input.tap()
        typeSlowly(text)
        app.buttons["chat.send"].tap()
    }

    @MainActor
    private func chatBubble(containing text: String) -> XCUIElement {
        let matches = NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "chat.message.", text)
        return app.descendants(matching: .any).matching(matches).firstMatch
    }
}
