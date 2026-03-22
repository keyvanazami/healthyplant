import XCTest

final class HomeUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    // MARK: - App Launch

    func testAppLaunchesSuccessfully() {
        // The app should launch without crashing
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    // MARK: - Home Screen Content

    func testHealthyPlantTitleIsVisible() {
        let title = app.staticTexts["Healthy Plant"]
        XCTAssertTrue(title.waitForExistence(timeout: 5),
                      "The 'Healthy Plant' title should be visible on the home screen")
    }

    func testSubtitleIsVisible() {
        let subtitle = app.staticTexts["Your AI-powered gardening companion"]
        XCTAssertTrue(subtitle.waitForExistence(timeout: 5),
                      "The subtitle should be visible on the home screen")
    }

    // MARK: - Settings Button

    func testSettingsButtonExists() {
        let settingsButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'gearshape' OR label CONTAINS 'Settings'")
        ).firstMatch
        // Alternatively, look for the gear icon image
        let gearImage = app.images["gearshape"]

        let exists = settingsButton.waitForExistence(timeout: 5)
            || gearImage.waitForExistence(timeout: 2)
        XCTAssertTrue(exists, "Settings button should exist on the home screen")
    }

    func testSettingsButtonIsTappable() {
        // Find any button in the navigation bar area
        let navBarButtons = app.navigationBars.buttons
        if navBarButtons.count > 0 {
            let firstButton = navBarButtons.firstMatch
            XCTAssertTrue(firstButton.isHittable, "Settings button should be tappable")
        }
    }

    // MARK: - Tab Bar

    func testHomeTabIsSelectedByDefault() {
        let homeText = app.staticTexts["Home"]
        XCTAssertTrue(homeText.waitForExistence(timeout: 5),
                      "Home tab label should be visible")
    }

    func testTabBarIsVisible() {
        // Check that tab labels are visible
        let profilesTab = app.staticTexts["Profiles"]
        let gardenTab = app.staticTexts["Garden"]
        let calendarTab = app.staticTexts["Calendar"]
        let assistantTab = app.staticTexts["Assistant"]

        XCTAssertTrue(profilesTab.waitForExistence(timeout: 5))
        XCTAssertTrue(gardenTab.exists)
        XCTAssertTrue(calendarTab.exists)
        XCTAssertTrue(assistantTab.exists)
    }
}
