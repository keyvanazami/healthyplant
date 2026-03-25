import Foundation

struct CalendarService {
    private let api = APIClient.shared

    // MARK: - Fetch Events for Month

    func fetchEvents(month: Date) async throws -> [CalendarEvent] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthString = formatter.string(from: month)

        return try await api.get(path: "/api/v1/calendar?month=\(monthString)")
    }

    // MARK: - Create Event

    func createEvent(
        profileId: String,
        plantName: String,
        date: String,
        eventType: String,
        description: String
    ) async throws -> CalendarEvent {
        let body = CreateEventRequest(
            profileId: profileId,
            plantName: plantName,
            date: date,
            eventType: eventType,
            description: description
        )
        return try await api.post(path: "/api/v1/calendar", body: body)
    }

    // MARK: - Generate Events

    func generateEvents() async throws -> [CalendarEvent] {
        return try await api.post(path: "/api/v1/calendar/generate", body: EmptyBody())
    }

    // MARK: - Mark Event Complete (legacy, no return value)

    func markEventComplete(id: String) async throws {
        let body = MarkCompleteRequest(completed: true)
        let _: CompleteEventResponse = try await api.put(path: "/api/v1/calendar/\(id)/complete", body: body)
    }

    // MARK: - Complete Event (returns response with optional next event)

    func completeEvent(id: String) async throws -> CompleteEventResponse {
        let body = MarkCompleteRequest(completed: true)
        return try await api.put(path: "/api/v1/calendar/\(id)/complete", body: body)
    }
}

// MARK: - Request/Response Bodies

private struct EmptyBody: Encodable {}

private struct MarkCompleteRequest: Encodable {
    let completed: Bool
}

struct CreateEventRequest: Encodable {
    let profileId: String
    let plantName: String
    let date: String
    let eventType: String
    let description: String
}

struct CompleteEventResponse: Codable {
    let id: String
    let userId: String
    let profileId: String
    var plantName: String
    var date: String
    var eventType: CalendarEvent.EventType
    var description: String
    var completed: Bool
    var completedAt: String?
    var nextEvent: CalendarEvent?
}
