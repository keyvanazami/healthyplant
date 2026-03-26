import XCTest
import SwiftUI
@testable import HealthyPlant

final class CalendarEventTests: XCTestCase {

    // MARK: - EventType Raw Values

    func testEventTypeRawValues() {
        XCTAssertEqual(CalendarEvent.EventType.needsWater.rawValue, "needs_water")
        XCTAssertEqual(CalendarEvent.EventType.needsSun.rawValue, "needs_sun")
        XCTAssertEqual(CalendarEvent.EventType.needsTreatment.rawValue, "needs_treatment")
    }

    func testEventTypeFromRawValue() {
        XCTAssertEqual(CalendarEvent.EventType(rawValue: "needs_water"), .needsWater)
        XCTAssertEqual(CalendarEvent.EventType(rawValue: "needs_sun"), .needsSun)
        XCTAssertEqual(CalendarEvent.EventType(rawValue: "needs_treatment"), .needsTreatment)
        XCTAssertNil(CalendarEvent.EventType(rawValue: "invalid"))
    }

    // MARK: - EventType Colors

    func testEventTypeColors() {
        XCTAssertEqual(CalendarEvent.EventType.needsWater.color, Color.blue)
        XCTAssertEqual(CalendarEvent.EventType.needsSun.color, Color.yellow)
        XCTAssertEqual(CalendarEvent.EventType.needsTreatment.color, Color.red)
    }

    // MARK: - EventType Labels

    func testEventTypeLabels() {
        XCTAssertEqual(CalendarEvent.EventType.needsWater.label, "Water")
        XCTAssertEqual(CalendarEvent.EventType.needsSun.label, "Sunlight")
        XCTAssertEqual(CalendarEvent.EventType.needsTreatment.label, "Treatment")
    }

    // MARK: - EventType Icons

    func testEventTypeIcons() {
        XCTAssertEqual(CalendarEvent.EventType.needsWater.icon, "drop.fill")
        XCTAssertEqual(CalendarEvent.EventType.needsSun.icon, "sun.max.fill")
        XCTAssertEqual(CalendarEvent.EventType.needsTreatment.icon, "cross.circle.fill")
    }

    // MARK: - CaseIterable

    func testEventTypeCaseIterable() {
        let allCases = CalendarEvent.EventType.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.needsWater))
        XCTAssertTrue(allCases.contains(.needsSun))
        XCTAssertTrue(allCases.contains(.needsTreatment))
    }

    // MARK: - Codable Round-Trip

    func testCodableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let event = CalendarEvent(
            id: "evt-test-001",
            userId: "user-001",
            profileId: "profile-001",
            plantName: "Tommy Tomato",
            date: "2023-11-14",
            eventType: .needsWater,
            description: "Water the tomato plant",
            completed: false
        )

        let data = try encoder.encode(event)
        let decoded = try decoder.decode(CalendarEvent.self, from: data)

        XCTAssertEqual(decoded.id, event.id)
        XCTAssertEqual(decoded.userId, event.userId)
        XCTAssertEqual(decoded.profileId, event.profileId)
        XCTAssertEqual(decoded.plantName, event.plantName)
        XCTAssertEqual(decoded.date, event.date)
        XCTAssertEqual(decoded.eventType, event.eventType)
        XCTAssertEqual(decoded.description, event.description)
        XCTAssertEqual(decoded.completed, event.completed)
    }

    func testCodableRoundTripCompleted() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let event = CalendarEvent(
            id: "evt-test-002",
            userId: "user-001",
            profileId: "profile-001",
            plantName: "Basil",
            date: "2023-11-14",
            eventType: .needsTreatment,
            description: "Apply neem oil",
            completed: true
        )

        let data = try encoder.encode(event)
        let decoded = try decoder.decode(CalendarEvent.self, from: data)

        XCTAssertTrue(decoded.completed)
        XCTAssertEqual(decoded.eventType, .needsTreatment)
    }

    func testCodableAllEventTypes() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for eventType in CalendarEvent.EventType.allCases {
            let event = CalendarEvent(
                id: "evt-\(eventType.rawValue)",
                userId: "user-001",
                profileId: "profile-001",
                plantName: "Test Plant",
                date: "2023-11-14",
                eventType: eventType,
                description: "Test \(eventType.label)",
                completed: false
            )

            let data = try encoder.encode(event)
            let decoded = try decoder.decode(CalendarEvent.self, from: data)
            XCTAssertEqual(decoded.eventType, eventType)
        }
    }

    // MARK: - Equatable

    func testEquatable() {
        let date = "2023-11-14"
        let event1 = CalendarEvent(
            id: "evt-001", userId: "user-001", profileId: "p-001",
            plantName: "Tomato", date: date, eventType: .needsWater,
            description: "Water it", completed: false
        )
        let event2 = event1

        XCTAssertEqual(event1, event2)
    }

    // MARK: - Mock

    func testMockIsValid() {
        let mock = CalendarEvent.mock
        XCTAssertEqual(mock.id, "evt-001")
        XCTAssertEqual(mock.eventType, .needsWater)
        XCTAssertFalse(mock.completed)
    }

    func testMockListHasMultipleEvents() {
        XCTAssertEqual(CalendarEvent.mockList.count, 3)
    }
}
