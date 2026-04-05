import Foundation

struct CommunityPlant: Codable, Identifiable, Hashable {
    let id: String
    let sourceUserId: String
    let sourceProfileId: String
    let displayName: String
    let name: String
    let plantType: String
    let photoURL: String?
    let gardenerAvatarURL: String?
    let ageDays: Int
    let heightFeet: Int
    let heightInches: Int
    let sunNeeds: String?
    let waterNeeds: String?
    let harvestTime: String?
    let sharedAt: String
    let commentCount: Int
    let isMine: Bool

    var formattedHeight: String {
        Int.formatHeight(feet: heightFeet, inches: heightInches)
    }
}
