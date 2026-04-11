import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool
    @Published var devModeUnlocked: Bool = UserDefaults.standard.bool(forKey: "hp_dev_mode_unlocked")
    @Published var isDevelopment: Bool = AppEnvironment.current == .development
    let appVersion: String = {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }()

    let buildDate: String = {
        guard let url = Bundle.main.executableURL,
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let date = attrs[.modificationDate] as? Date else { return "Unknown" }
        let f = DateFormatter()
        f.dateFormat = "MMM d yyyy, HH:mm"
        return f.string(from: date)
    }()

    private let notificationService = NotificationService()
    private var versionTapCount = 0
    private var lastTapTime: Date?

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

    func handleVersionTap() {
        let now = Date()
        if let last = lastTapTime, now.timeIntervalSince(last) > 2.0 {
            versionTapCount = 0
        }
        versionTapCount += 1
        lastTapTime = now

        if versionTapCount >= 5 {
            devModeUnlocked = true
            UserDefaults.standard.set(true, forKey: "hp_dev_mode_unlocked")
            versionTapCount = 0
        }
    }

    func toggleEnvironment() {
        let newEnv: AppEnvironment = isDevelopment ? .production : .development
        isDevelopment = (newEnv == .development)
        AppEnvironment.current = newEnv
    }
}
