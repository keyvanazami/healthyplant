import Foundation
import SwiftUI

struct CalendarEvent: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let profileId: String
    var plantName: String
    var date: Date
    var eventType: EventType
    var description: String
    var completed: Bool
    var completedAt: String?

    // MARK: - EventType

    enum EventType: String, Codable, CaseIterable {
        case needsWater = "needs_water"
        case needsSun = "needs_sun"
        case needsTreatment = "needs_treatment"

        var color: Color {
            switch self {
            case .needsWater: return .blue
            case .needsSun: return .yellow
            case .needsTreatment: return .red
            }
        }

        var label: String {
            switch self {
            case .needsWater: return "Water"
            case .needsSun: return "Sunlight"
            case .needsTreatment: return "Treatment"
            }
        }

        var icon: String {
            switch self {
            case .needsWater: return "drop.fill"
            case .needsSun: return "sun.max.fill"
            case .needsTreatment: return "cross.circle.fill"
            }
        }
    }

    // MARK: - Preview Mock

    static let mock = CalendarEvent(
        id: "evt-001",
        userId: "user-001",
        profileId: "mock-001",
        plantName: "Tommy Tomato",
        date: .now,
        eventType: .needsWater,
        description: "Water the tomato plant thoroughly.",
        completed: false
    )

    static let mockList: [CalendarEvent] = [
        mock,
        CalendarEvent(
            id: "evt-002",
            userId: "user-001",
            profileId: "mock-001",
            plantName: "Tommy Tomato",
            date: .now,
            eventType: .needsSun,
            description: "Move to a sunnier spot for at least 6 hours.",
            completed: false
        ),
        CalendarEvent(
            id: "evt-003",
            userId: "user-001",
            profileId: "mock-002",
            plantName: "Basil Buddy",
            date: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now,
            eventType: .needsTreatment,
            description: "Apply neem oil for aphid prevention.",
            completed: true
        ),
    ]
}
