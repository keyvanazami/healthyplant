import Foundation

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var communityPlants: [CommunityPlant] = []
    @Published var plantTypes: [String] = []
    @Published var selectedPlantType: String? = nil
    @Published var comments: [CommunityComment] = []
    @Published var mySharedIds: [String: String] = [:]  // sourceProfileId → communityId
    @Published var isLoading = false
    @Published var isLoadingComments = false
    @Published var errorMessage: String?

    private let communityService = CommunityService()

    var displayName: String {
        UserDefaults.standard.string(forKey: "hp_display_name") ?? "Plant Lover"
    }

    var hasSetDisplayName: Bool {
        UserDefaults.standard.string(forKey: "hp_display_name") != nil
    }

    func saveDisplayName(_ name: String) {
        UserDefaults.standard.set(name, forKey: "hp_display_name")
    }

    // MARK: - Load Community

    func loadCommunity() async {
        isLoading = true
        errorMessage = nil

        async let typesFetch = communityService.fetchPlantTypes()
        async let plantsFetch = communityService.fetchCommunityPlants()

        do {
            let (typesWrapper, plants) = try await (typesFetch, plantsFetch)
            plantTypes = typesWrapper.plantTypes
            communityPlants = plants
        } catch {
            errorMessage = error.localizedDescription
            print("[CommunityVM] Failed to load community: \(error)")
        }

        isLoading = false
    }

    func filterByType(_ type: String?) async {
        selectedPlantType = type
        isLoading = true

        do {
            communityPlants = try await communityService.fetchCommunityPlants(plantType: type)
        } catch {
            print("[CommunityVM] Failed to filter: \(error)")
        }

        isLoading = false
    }

    // MARK: - My Shared

    func loadMyShared() async {
        do {
            let shared = try await communityService.fetchMyShared()
            var mapping: [String: String] = [:]
            for plant in shared {
                mapping[plant.sourceProfileId] = plant.id
            }
            mySharedIds = mapping
        } catch {
            print("[CommunityVM] Failed to load my shared: \(error)")
        }
    }

    func isProfileShared(_ profileId: String) -> Bool {
        mySharedIds[profileId] != nil
    }

    // MARK: - Share / Unshare

    func shareProfile(profileId: String) async {
        do {
            let result = try await communityService.shareProfile(
                profileId: profileId,
                displayName: displayName
            )
            mySharedIds[profileId] = result.id
        } catch {
            print("[CommunityVM] Failed to share: \(error)")
        }
    }

    func unshareProfile(profileId: String) async {
        guard let communityId = mySharedIds[profileId] else { return }
        do {
            try await communityService.unshare(communityId: communityId)
            mySharedIds.removeValue(forKey: profileId)
        } catch {
            print("[CommunityVM] Failed to unshare: \(error)")
        }
    }

    // MARK: - Comments

    func loadComments(communityId: String) async {
        isLoadingComments = true
        do {
            comments = try await communityService.fetchComments(communityId: communityId)
        } catch {
            print("[CommunityVM] Failed to load comments: \(error)")
        }
        isLoadingComments = false
    }

    func postComment(communityId: String, content: String) async {
        do {
            let comment = try await communityService.postComment(
                communityId: communityId,
                content: content,
                displayName: displayName
            )
            comments.append(comment)
        } catch {
            print("[CommunityVM] Failed to post comment: \(error)")
        }
    }
}
