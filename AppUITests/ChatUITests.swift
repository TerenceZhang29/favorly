import XCTest

/// Chat between requester and helper (Phase 3C).
final class ChatUITests: UITestCase {
    @MainActor
    func testHelperAndRequesterHoldAConversation() {
        launchApp()
        postRiceRequestAsAlex()

        // Bea picks it up and says she is on her way.
        switchUser(to: "user-bea")
        openTab("Nearby")
        let rice = row("nearby.row.", containing: "Need a cup of rice")
        XCTAssertTrue(rice.waitForExistence(timeout: Self.waitTimeout))
        rice.tap()
        XCTAssertFalse(app.buttons["detail.message"].exists)
        app.buttons["detail.pickUp"].tap()
        app.buttons["Confirm pick up"].tap()
        waitFor(element("detail.status"), toRead: "Claimed by Bea")
        let message = app.buttons["detail.message"]
        XCTAssertTrue(message.waitForExistence(timeout: Self.waitTimeout))
        XCTAssertEqual(message.label, "Message Alex")
        message.tap()
        waitFor(element("chat.empty"), toRead: "Say hello")
        send("On my way")
        XCTAssertTrue(bubble(containing: "You said: On my way").waitForExistence(timeout: Self.waitTimeout))
        // Leave the chat, so the keyboard closes and the tab bar is visible again.
        app.navigationBars.buttons.firstMatch.tap()

        // Alex sees it and replies.
        switchUser(to: "user-alex")
        openTab("My Activity")
        let claimed = row("activity.row.", containing: "Claimed by Bea")
        XCTAssertTrue(claimed.waitForExistence(timeout: Self.waitTimeout))
        claimed.tap()
        scrollToAndTap(app.buttons["detail.message"])
        XCTAssertTrue(bubble(containing: "Bea said: On my way").waitForExistence(timeout: Self.waitTimeout))
        send("Thank you!")
        XCTAssertTrue(bubble(containing: "You said: Thank you!").waitForExistence(timeout: Self.waitTimeout))

        // Once completed, the thread is read-only.
        app.navigationBars.buttons.firstMatch.tap()
        scrollToAndTap(app.buttons["detail.complete"])
        waitFor(element("detail.status"), toRead: "Completed")
        scrollToAndTap(app.buttons["detail.message"])
        XCTAssertTrue(element("chat.closed").waitForExistence(timeout: Self.waitTimeout))
        XCTAssertFalse(element("chat.input").exists)
    }

    @MainActor
    func testNoMessageButtonOnSomeoneElsesClaimedRequest() {
        launchApp()
        switchUser(to: "user-bea")
        openTab("Nearby")
        // From Bea's view the ladder request (claimed by Chen for Dana) is not in Nearby, so open an open one.
        let eggs = row("nearby.row.", containing: "Need 2 eggs for a cake")
        XCTAssertTrue(eggs.waitForExistence(timeout: Self.waitTimeout))
        eggs.tap()
        waitFor(element("detail.status"), toRead: "Open")
        XCTAssertFalse(app.buttons["detail.message"].exists)
    }

    @MainActor
    private func postRiceRequestAsAlex() {
        openTab("Post")
        waitFor(element("post.location"), toRead: "Tagged at Roosevelt Island")
        app.textFields["post.title"].tap()
        app.typeText("Need a cup of rice\n")
        app.buttons["post.submit"].tap()
        XCTAssertTrue(row("activity.row.", containing: "Need a cup of rice")
            .waitForExistence(timeout: Self.waitTimeout))
    }

    @MainActor
    private func send(_ text: String) {
        let input = element("chat.input")
        XCTAssertTrue(input.waitForExistence(timeout: Self.waitTimeout))
        input.tap()
        app.typeText(text)
        app.buttons["chat.send"].tap()
    }

    @MainActor
    private func bubble(containing text: String) -> XCUIElement {
        let matches = NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "chat.message.", text)
        return app.descendants(matching: .any).matching(matches).firstMatch
    }
}
