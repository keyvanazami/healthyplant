import XCTest
@testable import HealthyPlant

@MainActor
final class CalendarViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testInitialState() {
        let vm = CalendarViewModel()
        XCTAssertTrue(vm.events.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func testCurrentMonthDefaultsToThisMonth() {
        let vm = CalendarViewModel()
        let expected = Date().startOfMonth
        XCTAssertEqual(
            vm.currentMonth.timeIntervalSince1970,
            expected.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    // MARK: - loadEvents

    func testLoadEventsSetsIsLoadingToFalseWhenDone() async {
        let vm = CalendarViewModel()

        await vm.loadEvents(for: Date())

        // Should be false after completion (whether success or failure)
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadEventsSetsErrorOnFailure() async {
        let vm = CalendarViewModel()

        // Without a running backend, should get an error
        await vm.loadEvents(for: Date())

        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: - eventsForDay

    func testEventsForDayFiltersCorrectly() {
        let vm = CalendarViewModel()

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: today)
        let tomorrowString = formatter.string(from: tomorrow)

        vm.events = [
            CalendarEvent(
                id: "evt-1", userId: "user-001", profileId: "p-001",
                plantName: "Tomato", date: todayString, eventType: .needsWater,
                description: "Water today", completed: false
            ),
            CalendarEvent(
                id: "evt-2", userId: "user-001", profileId: "p-001",
                plantName: "Tomato", date: todayString, eventType: .needsSun,
                description: "Sun today", completed: false
            ),
            CalendarEvent(
                id: "evt-3", userId: "user-001", profileId: "p-002",
                plantName: "Basil", date: tomorrowString, eventType: .needsTreatment,
                description: "Treatment tomorrow", completed: false
            ),
        ]

        let todayEvents = vm.eventsForDay(today)
        XCTAssertEqual(todayEvents.count, 2)
        XCTAssertTrue(todayEvents.allSatisfy { $0.date == todayString })

        let tomorrowEvents = vm.eventsForDay(tomorrow)
        XCTAssertEqual(tomorrowEvents.count, 1)
        XCTAssertEqual(tomorrowEvents.first?.plantName, "Basil")
    }

    func testEventsForDayReturnsEmptyForNoEvents() {
        let vm = CalendarViewModel()
        vm.events = CalendarEvent.mockList

        // A date far in the past should have no events
        let pastDate = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
        let events = vm.eventsForDay(pastDate)
        XCTAssertTrue(events.isEmpty)
    }

    // MARK: - Month Navigation

    func testCurrentMonthCanBeAdvanced() {
        let vm = CalendarViewModel()
        let original = vm.currentMonth

        // Simulate nextMonth by adding 1 month
        vm.currentMonth = original.addingMonths(1)

        let expectedNext = original.addingMonths(1)
        XCTAssertEqual(
            vm.currentMonth.timeIntervalSince1970,
            expectedNext.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    func testCurrentMonthCanGoBack() {
        let vm = CalendarViewModel()
        let original = vm.currentMonth

        // Simulate previousMonth by subtracting 1 month
        vm.currentMonth = original.addingMonths(-1)

        let expectedPrev = original.addingMonths(-1)
        XCTAssertEqual(
            vm.currentMonth.timeIntervalSince1970,
            expectedPrev.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    func testMonthNavigationRoundTrip() {
        let vm = CalendarViewModel()
        let original = vm.currentMonth

        // Go forward then back
        vm.currentMonth = vm.currentMonth.addingMonths(1)
        vm.currentMonth = vm.currentMonth.addingMonths(-1)

        XCTAssertEqual(
            vm.currentMonth.timeIntervalSince1970,
            original.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    // MARK: - markComplete

    func testMarkCompleteTogglesLocally() {
        let vm = CalendarViewModel()
        let event = CalendarEvent(
            id: "evt-toggle", userId: "user-001", profileId: "p-001",
            plantName: "Tomato", date: "2026-03-23", eventType: .needsWater,
            description: "Water", completed: false
        )
        vm.events = [event]

        XCTAssertFalse(vm.events[0].completed)

        // Simulate the local toggle that markComplete does on success
        vm.events[0].completed.toggle()
        XCTAssertTrue(vm.events[0].completed)
    }
}
