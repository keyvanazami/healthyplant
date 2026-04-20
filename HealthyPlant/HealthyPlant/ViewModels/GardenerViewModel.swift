import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class GardenerViewModel: ObservableObject {
    @Published var myProfile: GardenerProfile = .empty
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    // Edit state bound to profile views
    @Published var editBio: String = ""
    @Published var editExperience: GardeningExperience? = nil
    @Published var editIsPublic: Bool = true
    @Published var editClimateZone: String = ""
    @Published var pendingAvatarData: Data? = nil
    @Published var pendingAvatarImage: UIImage? = nil

    private let service = GardenerService()
    private let imageService = ImageUploadService()

    func loadMyProfile() async {
        isLoading = true
        defer { isLoading = false }
        do {
            myProfile = try await service.fetchMyProfile()
            editBio = myProfile.bio ?? ""
            editExperience = myProfile.experienceLevel
            editIsPublic = myProfile.isPublic
            editClimateZone = myProfile.climateZone ?? ""
        } catch {
            // Profile may not exist yet — that's fine
        }
    }

    func saveProfile() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            var avatarURL = myProfile.avatarURL
            if let data = pendingAvatarData {
                avatarURL = try await imageService.uploadImage(data)
                pendingAvatarData = nil
                pendingAvatarImage = nil
            }
            let bio = editBio.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedClimateZone = editClimateZone.trimmingCharacters(in: .whitespacesAndNewlines)
            myProfile = try await service.upsertMyProfile(
                bio: bio.isEmpty ? nil : bio,
                experienceLevel: editExperience,
                avatarURL: avatarURL,
                isPublic: editIsPublic,
                climateZone: trimmedClimateZone.isEmpty ? nil : trimmedClimateZone
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// True if the user has filled in at least one profile field.
    func hasProfile() -> Bool {
        myProfile.bio != nil || myProfile.experienceLevel != nil
    }

    func setAvatarImage(_ image: UIImage) {
        pendingAvatarImage = image
        pendingAvatarData = image.jpegData(compressionQuality: 0.8)
    }
}
