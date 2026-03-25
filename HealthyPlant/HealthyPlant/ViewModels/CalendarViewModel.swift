import Foundation

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var currentMonth: Date = Date().startOfMonth
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var errorMessage: String?

    private let calendarService = CalendarService()

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

    // MARK: - Generate Schedule

    func generateSchedule() async {
        isGenerating = true
        errorMessage = nil

        do {
            _ = try await calendarService.generateEvents()
            await loadEvents(for: currentMonth)
        } catch {
            errorMessage = error.localizedDescription
            print("[CalendarVM] Failed to generate schedule: \(error)")
        }

        isGenerating = false
    }

    // MARK: - Mark Complete

    func markComplete(eventId: String) async {
        do {
            let response = try await calendarService.completeEvent(id: eventId)
            if let index = events.firstIndex(where: { $0.id == eventId }) {
                events[index].completed = true
            }
            // If the backend auto-created a next recurring event, add it to
            // the local array if it falls within the current month view
            if let nextEvent = response.nextEvent {
                let monthStart = currentMonth
                let monthEnd = Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
                if nextEvent.date >= monthStart && nextEvent.date < monthEnd {
                    events.append(nextEvent)
                }
            }
        } catch {
            print("[CalendarVM] Failed to mark complete: \(error)")
        }
    }

    // MARK: - Computed

    func eventsForDay(_ date: Date) -> [CalendarEvent] {
        events.filter { $0.date.isSameDay(as: date) }
    }
}
