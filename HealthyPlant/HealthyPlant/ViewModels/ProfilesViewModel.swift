import Foundation

@MainActor
final class ProfilesViewModel: ObservableObject {
    @Published var profiles: [PlantProfile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let plantService = PlantService()

    // MARK: - Load

    func loadProfiles() async {
        isLoading = true
        errorMessage = nil

        do {
            profiles = try await plantService.fetchProfiles()
        } catch {
            errorMessage = error.localizedDescription
            print("[ProfilesVM] Failed to load profiles: \(error)")
        }

        isLoading = false
    }

    // MARK: - Create

    func createProfile(
        name: String,
        plantType: String,
        ageDays: Int,
        heightFeet: Int,
        heightInches: Int,
        imageData: Data?
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            // Upload image if provided
            var photoURL: String?
            if let data = imageData {
                let imageService = ImageUploadService()
                photoURL = try await imageService.uploadImage(data)
            }

            let profile = try await plantService.createProfile(
                name: name,
                plantType: plantType,
                ageDays: ageDays,
                heightFeet: heightFeet,
                heightInches: heightInches,
                photoURL: photoURL
            )
            profiles.append(profile)
        } catch {
            errorMessage = error.localizedDescription
            print("[ProfilesVM] Failed to create profile: \(error)")
        }

        isLoading = false
    }

    // MARK: - Update

    func updateProfile(
        id: String,
        name: String,
        plantType: String,
        ageDays: Int,
        heightFeet: Int,
        heightInches: Int
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            let updated = try await plantService.updateProfile(
                id: id,
                name: name,
                plantType: plantType,
                ageDays: ageDays,
                heightFeet: heightFeet,
                heightInches: heightInches
            )
            if let index = profiles.firstIndex(where: { $0.id == id }) {
                profiles[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
            print("[ProfilesVM] Failed to update profile: \(error)")
        }

        isLoading = false
    }

    // MARK: - Delete

    func deleteProfile(id: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await plantService.deleteProfile(id: id)
            profiles.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
            print("[ProfilesVM] Failed to delete profile: \(error)")
        }

        isLoading = false
    }
}
