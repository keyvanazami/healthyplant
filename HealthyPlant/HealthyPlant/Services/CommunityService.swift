import Foundation

struct CommunityService {
    private let api = APIClient.shared

    // MARK: - Share / Unshare

    func shareProfile(profileId: String, displayName: String) async throws -> CommunityPlant {
        let body = ShareRequestBody(profileId: profileId, displayName: displayName)
        return try await api.post(path: "/api/v1/community/share", body: body)
    }

    func unshare(communityId: String) async throws {
        try await api.delete(path: "/api/v1/community/\(communityId)")
    }

    func fetchMyShared() async throws -> [CommunityPlant] {
        return try await api.get(path: "/api/v1/community/mine")
    }

    // MARK: - Browse

    func fetchCommunityPlants(plantType: String? = nil) async throws -> [CommunityPlant] {
        var path = "/api/v1/community/plants"
        if let plantType {
            let encoded = plantType.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? plantType
            path += "?plantType=\(encoded)"
        }
        return try await api.get(path: path)
    }

    func fetchPlantDetail(communityId: String) async throws -> CommunityPlant {
        return try await api.get(path: "/api/v1/community/plants/\(communityId)")
    }

    func fetchPlantTypes() async throws -> PlantTypesWrapper {
        return try await api.get(path: "/api/v1/community/plant-types")
    }

    // MARK: - Comments

    func fetchComments(communityId: String) async throws -> [CommunityComment] {
        return try await api.get(path: "/api/v1/community/plants/\(communityId)/comments")
    }

    func postComment(communityId: String, content: String, displayName: String) async throws -> CommunityComment {
        let body = CommentRequestBody(content: content, displayName: displayName)
        return try await api.post(path: "/api/v1/community/plants/\(communityId)/comments", body: body)
    }
}

// MARK: - Request Bodies

private struct ShareRequestBody: Encodable {
    let profileId: String
    let displayName: String
}

private struct CommentRequestBody: Encodable {
    let content: String
    let displayName: String
}

struct PlantTypesWrapper: Codable {
    let plantTypes: [String]
}
