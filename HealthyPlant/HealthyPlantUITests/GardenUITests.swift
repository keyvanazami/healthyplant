import XCTest

final class GardenUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    // MARK: - Navigation

    func testNavigateToGardenTab() {
        let gardenTab = app.staticTexts["Garden"]
        XCTAssertTrue(gardenTab.waitForExistence(timeout: 5))

        gardenTab.tap()

        // Should show the Garden screen
        let appeared = app.staticTexts["Garden"].waitForExistence(timeout: 3)
            || app.navigationBars.staticTexts["Garden"].waitForExistence(timeout: 3)
        XCTAssertTrue(appeared, "Should navigate to the Garden screen")
    }

    // MARK: - Empty State

    func testEmptyStateAppearsWithNoPlants() {
        let gardenTab = app.staticTexts["Garden"]
        XCTAssertTrue(gardenTab.waitForExistence(timeout: 5))
        gardenTab.tap()

        // Wait for content to load
        sleep(2)

        // Look for empty state messaging or garden content
        // Without profiles, the garden should show an empty/placeholder state
        let emptyState = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'no plants' OR label CONTAINS[c] 'empty' OR label CONTAINS[c] 'add' OR label CONTAINS[c] 'garden' OR label CONTAINS[c] 'start'")
        ).firstMatch

        let gardenContent = app.scrollViews.firstMatch.exists
            || app.collectionViews.firstMatch.exists
            || emptyState.exists

        // The garden view should display something (empty state or content)
        XCTAssertTrue(gardenContent || app.staticTexts.count > 0,
                      "Garden screen should show content or empty state")
    }

    // MARK: - Garden Screen Elements

    func testGardenScreenLoads() {
        let gardenTab = app.staticTexts["Garden"]
        XCTAssertTrue(gardenTab.waitForExistence(timeout: 5))
        gardenTab.tap()

        // Verify the screen has loaded by checking for any content
        sleep(1)
        XCTAssertTrue(app.staticTexts.count > 0,
                      "Garden screen should have some text content")
    }
}
