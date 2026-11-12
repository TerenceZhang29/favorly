import XCTest

/// The Messages tab, its unread badge and the incoming-message banner.
final class MessagesUITests: UITestCase {
    @MainActor
    func testTheInboxShowsANewMessageUntilItIsRead() {
        launchApp()
        // Alex asks; Bea claims it and writes.
        openTab("Post")
        waitFor(element("post.location"), toRead: "Tagged at Roosevelt Island")
        app.textFields["post.title"].tap()
        app.typeText("Need a cup of rice\n")
        scrollToAndTap(app.buttons["post.submit"])
        XCTAssertTrue(row("activity.row.", containing: "Need a cup of rice")
            .waitForExistence(timeout: Self.waitTimeout))

        switchUser(to: "user-bea")
        openTab("Nearby")
        let rice = row("nearby.row.", containing: "Need a cup of rice")
        XCTAssertTrue(rice.waitForExistence(timeout: Self.waitTimeout))
        rice.tap()
        app.buttons["detail.pickUp"].tap()
        app.buttons["claim.confirm"].tap()
        let message = app.buttons["detail.message"]
        XCTAssertTrue(message.waitForExistence(timeout: Self.waitTimeout))
        message.tap()
        send("On my way")
        goBack()

        // Alex sees it on the Messages tab, unread, until he opens it.
        switchUser(to: "user-alex")
        waitFor(tabButton("Messages"), toRead: "1 unread")
        openTab("Messages")
        let thread = row("inbox.row.", containing: "On my way")
        XCTAssertTrue(thread.waitForExistence(timeout: Self.waitTimeout))
        XCTAssertTrue(thread.label.contains("Bea, Your request, Need a cup of rice."))
        XCTAssertTrue(thread.label.contains("1 unread"))
        thread.tap()
        XCTAssertTrue(bubble(containing: "Bea said: On my way").waitForExistence(timeout: Self.waitTimeout))
        goBack()
        XCTAssertTrue(row("inbox.row.", containing: "On my way").waitForExistence(timeout: Self.waitTimeout))
        XCTAssertFalse(row("inbox.row.", containing: "unread").exists)
        XCTAssertEqual(tabButton("Messages").value as? String ?? "", "")
    }

    @MainActor
    func testTheBannerOpensTheChatOnReply() {
        launchApp()
        receiveMessageAsChen()

        let banner = element("banner")
        XCTAssertTrue(banner.waitForExistence(timeout: Self.waitTimeout))
        waitFor(element("banner.text"), toRead: "Hi! Checking in about Hold a ladder while I change a bulb.")
        app.buttons["banner.reply"].tap()

        XCTAssertTrue(bubble(containing: "Dana said: Hi! Checking in").waitForExistence(timeout: Self.waitTimeout))
        XCTAssertFalse(element("banner").exists)
    }

    @MainActor
    func testLaterDismissesTheBannerAndTheMessageWaitsInTheInbox() {
        launchApp()
        receiveMessageAsChen()

        XCTAssertTrue(element("banner").waitForExistence(timeout: Self.waitTimeout))
        app.buttons["banner.later"].tap()
        XCTAssertTrue(element("banner").waitForNonExistence(timeout: Self.waitTimeout))
        waitFor(tabButton("Messages"), toRead: "1 unread")
        openTab("Messages")
        XCTAssertTrue(row("inbox.row.", containing: "1 unread").waitForExistence(timeout: Self.waitTimeout))
    }

    /// Chen is helping Dana with the ladder; Dev Settings has Dana write to him.
    @MainActor
    private func receiveMessageAsChen() {
        switchUser(to: "user-chen")
        let receive = app.buttons["devSettings.receiveMessage"]
        for _ in 0 ..< 4 where !(receive.exists && receive.isHittable) {
            app.swipeUp()
        }
        receive.tap()
    }

    @MainActor
    private func send(_ text: String) {
        let input = element("chat.input")
        XCTAssertTrue(input.waitForExistence(timeout: Self.waitTimeout))
        input.tap()
        app.typeText(text)
        app.buttons["chat.send"].tap()
        XCTAssertTrue(bubble(containing: "You said: \(text)").waitForExistence(timeout: Self.waitTimeout))
    }

    @MainActor
    private func bubble(containing text: String) -> XCUIElement {
        let matches = NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "chat.message.", text)
        return app.descendants(matching: .any).matching(matches).firstMatch
    }
}
