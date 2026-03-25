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

    // MARK: - Generate Events

    func generateEvents() async throws -> [CalendarEvent] {
        return try await api.post(path: "/api/v1/calendar/generate")
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

private struct MarkCompleteRequest: Encodable {
    let completed: Bool
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
