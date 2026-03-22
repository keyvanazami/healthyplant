import Foundation

struct PlantService {
    private let api = APIClient.shared

    // MARK: - Fetch All Profiles

    func fetchProfiles() async throws -> [PlantProfile] {
        try await api.get(path: "/api/profiles")
    }

    // MARK: - Create Profile

    func createProfile(
        name: String,
        plantType: String,
        ageDays: Int,
        heightFeet: Int,
        heightInches: Int,
        photoURL: String? = nil
    ) async throws -> PlantProfile {
        let body = CreateProfileRequest(
            name: name,
            plantType: plantType,
            ageDays: ageDays,
            heightFeet: heightFeet,
            heightInches: heightInches,
            photoURL: photoURL
        )
        return try await api.post(path: "/api/profiles", body: body)
    }

    // MARK: - Update Profile

    func updateProfile(
        id: String,
        name: String,
        plantType: String,
        ageDays: Int,
        heightFeet: Int,
        heightInches: Int
    ) async throws -> PlantProfile {
        let body = UpdateProfileRequest(
            name: name,
            plantType: plantType,
            ageDays: ageDays,
            heightFeet: heightFeet,
            heightInches: heightInches
        )
        return try await api.put(path: "/api/profiles/\(id)", body: body)
    }

    // MARK: - Delete Profile

    func deleteProfile(id: String) async throws {
        try await api.delete(path: "/api/profiles/\(id)")
    }

    // MARK: - Fetch Garden (same data, different endpoint for garden-specific logic)

    func fetchGarden() async throws -> [PlantProfile] {
        try await api.get(path: "/api/profiles")
    }
}

// MARK: - Request Bodies

struct CreateProfileRequest: Encodable {
    let name: String
    let plantType: String
    let ageDays: Int
    let heightFeet: Int
    let heightInches: Int
    let photoURL: String?
}

struct UpdateProfileRequest: Encodable {
    let name: String
    let plantType: String
    let ageDays: Int
    let heightFeet: Int
    let heightInches: Int
}
