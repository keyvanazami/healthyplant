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

    // MARK: - Mark Event Complete

    func markEventComplete(id: String) async throws {
        let body = MarkCompleteRequest(completed: true)
        let _: CalendarEvent = try await api.put(path: "/api/v1/calendar/\(id)/complete", body: body)
    }
}

// MARK: - Request Body

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
