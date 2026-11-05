import XCTest

final class LaunchUITests: UITestCase {
    @MainActor
    func testLaunchShowsFiveTabs() {
        launchApp()

        for title in ["Nearby", "Post", "My Activity", "Profile", "Dev Settings"] {
            XCTAssertTrue(
                tabButton(title).waitForExistence(timeout: Self.waitTimeout),
                "Missing tab: \(title)"
            )
        }
    }

    /// A launch without `-uiTesting` or `-demo` is what a downloaded app does: it starts at Welcome.
    @MainActor
    func testLaunchWithoutFlagsStartsAtWelcome() {
        app.launch()
        XCTAssertTrue(app.buttons["welcome.signIn"].waitForExistence(timeout: Self.waitTimeout))
        XCTAssertFalse(app.buttons["tab.nearby"].exists)
    }

    @MainActor
    func testDemoLaunchStillLoadsNearbyWithTheDelay() {
        app.launchArguments = ["-demo"]
        app.launch()
        waitFor(element("nearby.count"), toRead: "7 requests")
    }
}
