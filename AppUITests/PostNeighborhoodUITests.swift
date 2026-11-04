import XCTest

/// The neighborhood is picked from the names offered nearby, and the optional meeting spot is shown with it.
final class PostNeighborhoodUITests: UITestCase {
    @MainActor
    func testPostingWithAPickedNeighborhoodAndAMeetingSpot() {
        launchApp()
        openTab("Post")
        waitFor(element("post.location"), toRead: "Tagged at Roosevelt Island")

        app.buttons["post.neighborhood"].tap()
        app.buttons["Long Island City"].tap()
        waitFor(element("post.location"), toRead: "Tagged at Long Island City")

        app.textFields["post.title"].tap()
        app.typeText("Need a cup of rice\n")
        let spot = app.textFields["post.meetingSpot"]
        spot.tap()
        app.typeText("Apt 4B")
        waitFor(
            element("post.meetingSpotMessage"),
            toRead: "Use only letters for the meeting spot, not a street address."
        )
        XCTAssertFalse(app.buttons["post.submit"].isEnabled)
        app.typeText(String(repeating: "\u{8}", count: 6) + "Cornell Tech lobby\n")
        app.buttons["post.submit"].tap()

        let posted = row("activity.row.", containing: "Need a cup of rice")
        XCTAssertTrue(posted.waitForExistence(timeout: Self.waitTimeout))
        posted.tap()
        waitFor(element("detail.location"), toRead: "Long Island City")
        waitFor(element("detail.meetingSpot"), toRead: "Cornell Tech lobby")
    }
}
