import Foundation

enum AppEnvironment: String, CaseIterable {
    case production = "production"
    case development = "development"

    var baseURL: String {
        switch self {
        case .production:
            return "https://healthyplant-api-prod-680872497777.us-central1.run.app"
        case .development:
            return "https://healthy-plant-api-dev-680872497777.us-central1.run.app"
        }
    }

    var displayName: String {
        switch self {
        case .production: return "Production"
        case .development: return "Development"
        }
    }

    static var current: AppEnvironment {
        get {
            let raw = UserDefaults.standard.string(forKey: "hp_environment") ?? "production"
            return AppEnvironment(rawValue: raw) ?? .production
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "hp_environment")
        }
    }
}
