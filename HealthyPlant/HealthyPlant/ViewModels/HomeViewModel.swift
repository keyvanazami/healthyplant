import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var plants: [PlantProfile] = []
    @Published var todayEvents: [CalendarEvent] = []
    @Published var completedTodayCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let plantService = PlantService()
    private let calendarService = CalendarService()

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        async let profilesFetch = plantService.fetchProfiles()
        async let eventsFetch = calendarService.fetchEvents(month: Date())

        do {
            let (fetchedPlants, allEvents) = try await (profilesFetch, eventsFetch)
            plants = fetchedPlants
            let todayAll = allEvents.filter { $0.date == todayString }
            todayEvents = todayAll.filter { !$0.completed }
            completedTodayCount = todayAll.filter { $0.completed }.count
        } catch {
            errorMessage = error.localizedDescription
            print("[HomeVM] Failed to load dashboard: \(error)")
        }

        isLoading = false
    }

    func completeTask(eventId: String) async {
        do {
            _ = try await calendarService.completeEvent(id: eventId)
            todayEvents.removeAll { $0.id == eventId }
            completedTodayCount += 1
        } catch {
            print("[HomeVM] Failed to complete task: \(error)")
        }
    }
}
