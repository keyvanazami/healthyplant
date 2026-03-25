import Foundation

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var profiles: [PlantProfile] = []
    @Published var currentMonth: Date = Date().startOfMonth
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let calendarService = CalendarService()
    private let plantService = PlantService()

    // MARK: - Load Events

    func loadEvents(for month: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            events = try await calendarService.fetchEvents(month: month)
        } catch {
            errorMessage = error.localizedDescription
            print("[CalendarVM] Failed to load events: \(error)")
        }

        isLoading = false
    }

    // MARK: - Load Profiles

    func loadProfiles() async {
        do {
            profiles = try await plantService.fetchProfiles()
        } catch {
            print("[CalendarVM] Failed to load profiles: \(error)")
        }
    }

    // MARK: - Create Event

    func createEvent(
        profileId: String,
        plantName: String,
        date: String,
        eventType: String,
        description: String
    ) async {
        do {
            _ = try await calendarService.createEvent(
                profileId: profileId,
                plantName: plantName,
                date: date,
                eventType: eventType,
                description: description
            )
            await loadEvents(for: currentMonth)
        } catch {
            errorMessage = error.localizedDescription
            print("[CalendarVM] Failed to create event: \(error)")
        }
    }

    // MARK: - Mark Complete

    func markComplete(eventId: String) async {
        do {
            try await calendarService.markEventComplete(id: eventId)
            if let index = events.firstIndex(where: { $0.id == eventId }) {
                events[index].completed.toggle()
            }
        } catch {
            print("[CalendarVM] Failed to mark complete: \(error)")
        }
    }

    // MARK: - Computed

    func eventsForDay(_ date: Date) -> [CalendarEvent] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return events.filter { $0.date == dateString }
    }
}
