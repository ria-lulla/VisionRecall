import XCTest

final class VisionRecallUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesToTabs() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Reminders"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["Memory Keys"].exists)
        XCTAssertTrue(app.tabBars.buttons["Live"].exists)
    }
}
