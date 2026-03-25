import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var userId: String
    @Published var isAuthenticated: Bool
    @Published var notificationsEnabled: Bool
    @Published var environment: AppEnvironment

    init() {
        // Retrieve or generate a persistent anonymous user ID
        if let stored = UserDefaults.standard.string(forKey: "hp_user_id") {
            self.userId = stored
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "hp_user_id")
            self.userId = newId
        }
        self.isAuthenticated = true // anonymous auth by default
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "hp_notifications_enabled")
        self.environment = AppEnvironment.current
    }

    func setNotifications(enabled: Bool) {
        notificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "hp_notifications_enabled")
    }

    func switchEnvironment(_ env: AppEnvironment) {
        environment = env
        AppEnvironment.current = env
    }
}
