import Foundation

struct CommunityComment: Codable, Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let content: String
    let createdAt: String
}
