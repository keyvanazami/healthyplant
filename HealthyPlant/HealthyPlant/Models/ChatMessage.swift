import Foundation

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    var role: Role
    var content: String
    var timestamp: Date

    enum Role: String, Codable {
        case user
        case assistant
    }

    // MARK: - Preview Mock

    static let mock = ChatMessage(
        id: "msg-001",
        userId: "user-001",
        role: .user,
        content: "How often should I water my tomato plant?",
        timestamp: .now
    )

    static let mockConversation: [ChatMessage] = [
        mock,
        ChatMessage(
            id: "msg-002",
            userId: "user-001",
            role: .assistant,
            content: "Tomato plants generally need watering every 2-3 days, depending on the weather and soil conditions. In hot weather, you may need to water daily. The key is to keep the soil consistently moist but not waterlogged.",
            timestamp: .now
        ),
    ]
}
