import XCTest

final class DevSettingsUITests: UITestCase {
    @MainActor
    func testSwitchingUserAndLocationUpdatesSettingsAndNearby() {
        launchApp()

        let header = element("nearby.location")
        waitFor(header, toRead: "Near Cornell Tech, Roosevelt Island")

        openTab("Dev Settings")
        waitFor(element("devSettings.summary"), toRead: "Alex @ Cornell Tech, Roosevelt Island")
        app.buttons["devSettings.user.user-bea"].tap()
        waitFor(element("devSettings.summary"), toRead: "Bea @ Cornell Tech, Roosevelt Island")
        // Tapping the last preset scrolls the summary row off screen, so the result is checked on Nearby.
        app.buttons["devSettings.location.ithaca"].tap()

        openTab("Nearby")
        waitFor(header, toRead: "Near Ithaca, NY")
    }
}
