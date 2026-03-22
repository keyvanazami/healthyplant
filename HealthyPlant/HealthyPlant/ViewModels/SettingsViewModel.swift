import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool
    let appVersion = "1.0"

    private let notificationService = NotificationService()

    init() {
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "hp_notifications_enabled")
    }

    func toggleNotifications() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "hp_notifications_enabled")

        if notificationsEnabled {
            Task {
                let granted = await notificationService.requestPermission()
                if !granted {
                    notificationsEnabled = false
                    UserDefaults.standard.set(false, forKey: "hp_notifications_enabled")
                }
            }
        }
    }
}
