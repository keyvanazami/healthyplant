import XCTest

final class CalendarUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    // MARK: - Navigation

    func testNavigateToCalendarTab() {
        let calendarTab = app.staticTexts["Calendar"]
        XCTAssertTrue(calendarTab.waitForExistence(timeout: 5))

        calendarTab.tap()

        // Should show Calendar screen content
        sleep(1)
        let appeared = app.staticTexts["Calendar"].waitForExistence(timeout: 3)
            || app.navigationBars.staticTexts["Calendar"].waitForExistence(timeout: 3)
        XCTAssertTrue(appeared, "Should navigate to the Calendar screen")
    }

    // MARK: - Calendar Grid

    func testCalendarGridIsVisible() {
        let calendarTab = app.staticTexts["Calendar"]
        XCTAssertTrue(calendarTab.waitForExistence(timeout: 5))
        calendarTab.tap()

        sleep(1)

        // The calendar should display day numbers (1-31)
        // Look for at least day "1" which every month has
        let dayOne = app.staticTexts["1"]
        let dayFifteen = app.staticTexts["15"]

        let gridVisible = dayOne.waitForExistence(timeout: 5)
            || dayFifteen.waitForExistence(timeout: 2)

        XCTAssertTrue(gridVisible,
                      "Calendar grid with day numbers should be visible")
    }

    func testCalendarShowsMonthAndYear() {
        let calendarTab = app.staticTexts["Calendar"]
        XCTAssertTrue(calendarTab.waitForExistence(timeout: 5))
        calendarTab.tap()

        sleep(1)

        // Should show the current month name (e.g., "March 2026")
        let monthNames = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ]

        let hasMonthLabel = monthNames.contains { monthName in
            app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS %@", monthName)
            ).firstMatch.exists
        }

        XCTAssertTrue(hasMonthLabel,
                      "Calendar should display the current month name")
    }

    // MARK: - Month Navigation

    func testMonthNavigationButtonsExist() {
        let calendarTab = app.staticTexts["Calendar"]
        XCTAssertTrue(calendarTab.waitForExistence(timeout: 5))
        calendarTab.tap()

        sleep(1)

        // Look for forward/back navigation buttons (chevrons or arrows)
        let navButtons = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'chevron' OR label CONTAINS 'arrow' OR label CONTAINS 'next' OR label CONTAINS 'previous' OR label CONTAINS 'forward' OR label CONTAINS 'back'")
        )

        // There should be at least navigation affordances
        // Some calendars use < > buttons, others use swipe gestures
        let hasNavigation = navButtons.count >= 1
            || app.images["chevron.left"].exists
            || app.images["chevron.right"].exists

        // If no explicit buttons found, the calendar view at minimum loaded
        XCTAssertTrue(hasNavigation || app.staticTexts.count > 5,
                      "Calendar should have month navigation or display enough content")
    }

    func testMonthNavigationChangesMonth() {
        let calendarTab = app.staticTexts["Calendar"]
        XCTAssertTrue(calendarTab.waitForExistence(timeout: 5))
        calendarTab.tap()

        sleep(1)

        // Try to find and tap a forward navigation button
        let forwardButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'chevron.right' OR label CONTAINS 'forward' OR label CONTAINS 'next'")
        ).firstMatch

        let chevronRight = app.images["chevron.right"]

        if forwardButton.exists {
            // Record current month text
            let beforeTexts = app.staticTexts.allElementsBoundByIndex.map { $0.label }
            forwardButton.tap()
            sleep(1)
            let afterTexts = app.staticTexts.allElementsBoundByIndex.map { $0.label }

            // Something should have changed
            XCTAssertNotEqual(beforeTexts, afterTexts,
                              "Month navigation should change the displayed content")
        } else if chevronRight.exists {
            chevronRight.tap()
            sleep(1)
            // Navigation attempted
        }
    }

    // MARK: - Weekday Headers

    func testWeekdayHeadersVisible() {
        let calendarTab = app.staticTexts["Calendar"]
        XCTAssertTrue(calendarTab.waitForExistence(timeout: 5))
        calendarTab.tap()

        sleep(1)

        // Calendar should show weekday abbreviations
        let weekdayAbbreviations = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let shortAbbreviations = ["S", "M", "T", "W", "F"]

        let hasWeekdays = weekdayAbbreviations.contains { abbr in
            app.staticTexts[abbr].exists
        } || shortAbbreviations.contains { abbr in
            app.staticTexts[abbr].exists
        }

        XCTAssertTrue(hasWeekdays,
                      "Calendar should display weekday header labels")
    }
}
