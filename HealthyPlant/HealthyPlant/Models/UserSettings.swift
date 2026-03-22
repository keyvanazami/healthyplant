import Foundation

struct UserSettings: Codable, Equatable {
    let userId: String
    var notificationsEnabled: Bool
    var fcmToken: String?

    // MARK: - Preview Mock

    static let mock = UserSettings(
        userId: "user-001",
        notificationsEnabled: true,
        fcmToken: nil
    )
}
