import Foundation

extension Notification.Name {
    static let sensorDeleted = Notification.Name("SensorDeleted")
}

@MainActor
final class ProfilesViewModel: ObservableObject {
    @Published var profiles: [PlantProfile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let plantService = PlantService()
    private var sensorDeletedObserver: Any?

    init() {
        sensorDeletedObserver = NotificationCenter.default.addObserver(
            forName: .sensorDeleted, object: nil, queue: .main
        ) { [weak self] _ in
            Task { await self?.loadProfiles() }
        }
    }

    deinit {
        if let observer = sensorDeletedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Load

    func loadProfiles() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await plantService.fetchProfiles()
            print("[ProfilesVM] Loaded \(fetched.count) profiles")
            profiles = fetched
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
        imageData: Data?,
        isIndoor: Bool = false
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            // Upload image if provided (non-blocking — profile saves even if upload fails)
            var photoURL: String?
            if let data = imageData {
                do {
                    let imageService = ImageUploadService()
                    photoURL = try await imageService.uploadImage(data)
                } catch {
                    print("[ProfilesVM] Image upload failed (continuing without photo): \(error)")
                }
            }

            print("[ProfilesVM] Sending create request: name=\(name) type=\(plantType) ageDays=\(ageDays)")
            let profile = try await plantService.createProfile(
                name: name,
                plantType: plantType,
                ageDays: ageDays,
                heightFeet: heightFeet,
                heightInches: heightInches,
                photoURL: photoURL,
                isIndoor: isIndoor
            )
            print("[ProfilesVM] Created profile: \(profile.id) - \(profile.name)")
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
        heightInches: Int,
        isIndoor: Bool
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
                heightInches: heightInches,
                isIndoor: isIndoor
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

    // MARK: - Update Photo

    func updateProfilePhoto(id: String, photoURL: String) async {
        do {
            let updated = try await plantService.updateProfilePhoto(id: id, photoURL: photoURL)
            if let index = profiles.firstIndex(where: { $0.id == id }) {
                profiles[index] = updated
            }
            print("[ProfilesVM] Photo updated for profile \(id)")
        } catch {
            print("[ProfilesVM] Failed to update photo: \(error)")
        }
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
