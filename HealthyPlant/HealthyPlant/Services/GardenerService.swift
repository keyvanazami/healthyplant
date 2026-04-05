import Foundation

enum GardenerServiceError: Error {
    case signInRequired
    case notFound
}

struct GardenerService {
    private let api = APIClient.shared

    func fetchMyProfile() async throws -> GardenerProfile {
        try await api.get(path: "/api/v1/gardeners/me")
    }

    func upsertMyProfile(
        bio: String?,
        experienceLevel: GardeningExperience?,
        avatarURL: String?,
        isPublic: Bool
    ) async throws -> GardenerProfile {
        let body = GardenerUpsertBody(
            bio: bio,
            experienceLevel: experienceLevel?.rawValue,
            avatarURL: avatarURL,
            isPublic: isPublic
        )
        return try await api.put(path: "/api/v1/gardeners/me", body: body)
    }

    func registerFCMToken(_ token: String) async throws {
        let body = FCMTokenBody(fcmToken: token)
        let _: NoContentResponse = try await api.put(path: "/api/v1/gardeners/me/fcm-token", body: body)
    }

    func fetchProfile(userId: String) async throws -> GardenerProfile {
        do {
            return try await api.get(path: "/api/v1/gardeners/\(userId)")
        } catch APIError.httpError(let code, _) where code == 403 {
            throw GardenerServiceError.signInRequired
        } catch APIError.httpError(let code, _) where code == 404 {
            throw GardenerServiceError.notFound
        }
    }

    func fetchGardenerPlants(userId: String) async throws -> [CommunityPlant] {
        try await api.get(path: "/api/v1/gardeners/\(userId)/plants")
    }

    func followGardener(userId: String) async throws -> FollowResponse {
        do {
            return try await api.post(path: "/api/v1/gardeners/\(userId)/follow", body: EmptyBody())
        } catch APIError.httpError(let code, _) where code == 403 {
            throw GardenerServiceError.signInRequired
        }
    }

    func unfollowGardener(userId: String) async throws {
        try await api.delete(path: "/api/v1/gardeners/\(userId)/follow")
    }

    func fetchMyFollowing() async throws -> [GardenerProfile] {
        try await api.get(path: "/api/v1/gardeners/me/following")
    }
}

// MARK: - Private request bodies

private struct GardenerUpsertBody: Encodable {
    let bio: String?
    let experienceLevel: String?
    let avatarURL: String?
    let isPublic: Bool
}

private struct FCMTokenBody: Encodable {
    let fcmToken: String
}

private struct EmptyBody: Encodable {}
private struct NoContentResponse: Decodable {}
