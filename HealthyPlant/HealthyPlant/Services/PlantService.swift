import Foundation

struct PlantService {
    private let api = APIClient.shared

    // MARK: - Fetch All Profiles

    func fetchProfiles() async throws -> [PlantProfile] {
        try await api.get(path: "/api/v1/profiles")
    }

    // MARK: - Create Profile

    func createProfile(
        name: String,
        plantType: String,
        ageDays: Int,
        heightFeet: Int,
        heightInches: Int,
        photoURL: String? = nil,
        isIndoor: Bool = false
    ) async throws -> PlantProfile {
        let plantedDate = Calendar.current.date(byAdding: .day, value: -ageDays, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let body = CreateProfileRequest(
            name: name,
            plantType: plantType,
            ageDays: ageDays,
            plantedDate: formatter.string(from: plantedDate),
            heightFeet: heightFeet,
            heightInches: heightInches,
            photoURL: photoURL,
            isIndoor: isIndoor
        )
        return try await api.post(path: "/api/v1/profiles", body: body)
    }

    // MARK: - Update Profile

    func updateProfile(
        id: String,
        name: String,
        plantType: String,
        ageDays: Int,
        heightFeet: Int,
        heightInches: Int,
        isIndoor: Bool
    ) async throws -> PlantProfile {
        let body = UpdateProfileRequest(
            name: name,
            plantType: plantType,
            ageDays: ageDays,
            heightFeet: heightFeet,
            heightInches: heightInches,
            isIndoor: isIndoor
        )
        return try await api.put(path: "/api/v1/profiles/\(id)", body: body)
    }

    // MARK: - Update Photo

    func updateProfilePhoto(id: String, photoURL: String) async throws -> PlantProfile {
        let body = UpdatePhotoRequest(photoURL: photoURL)
        return try await api.put(path: "/api/v1/profiles/\(id)", body: body)
    }

    // MARK: - Delete Profile

    func deleteProfile(id: String) async throws {
        try await api.delete(path: "/api/v1/profiles/\(id)")
    }

    // MARK: - Fetch Garden (same data, different endpoint for garden-specific logic)

    func fetchGarden() async throws -> [PlantProfile] {
        try await api.get(path: "/api/v1/profiles")
    }
}

// MARK: - Request Bodies

struct CreateProfileRequest: Encodable {
    let name: String
    let plantType: String
    let ageDays: Int
    let plantedDate: String
    let heightFeet: Int
    let heightInches: Int
    let photoURL: String?
    let isIndoor: Bool
}

struct UpdateProfileRequest: Encodable {
    let name: String
    let plantType: String
    let ageDays: Int
    let heightFeet: Int
    let heightInches: Int
    let isIndoor: Bool
}

struct UpdatePhotoRequest: Encodable {
    let photoURL: String
}
