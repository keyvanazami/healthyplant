import Foundation

@MainActor
final class GardenViewModel: ObservableObject {
    @Published var plants: [PlantProfile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let plantService = PlantService()

    func loadGarden() async {
        isLoading = true
        errorMessage = nil

        do {
            plants = try await plantService.fetchGarden()
        } catch {
            errorMessage = error.localizedDescription
            print("[GardenVM] Failed to load garden: \(error)")
        }

        isLoading = false
    }
}
