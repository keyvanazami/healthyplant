import Foundation

@MainActor
final class AuthService: ObservableObject {
    @Published var userId: String
    @Published var isAuthenticated: Bool

    private static let userIdKey = "hp_user_id"

    init() {
        if let stored = UserDefaults.standard.string(forKey: Self.userIdKey) {
            self.userId = stored
            self.isAuthenticated = true
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: Self.userIdKey)
            self.userId = newId
            self.isAuthenticated = true
        }
    }

    /// Sign out and generate a new anonymous identity.
    func signOut() {
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: Self.userIdKey)
        userId = newId
    }

    // Convenience nonisolated access for services that need the userId off main actor
    nonisolated var storedUserId: String {
        UserDefaults.standard.string(forKey: Self.userIdKey) ?? "unknown"
    }
}
