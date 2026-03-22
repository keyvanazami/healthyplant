import SwiftUI

@main
struct HealthyPlantApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authService)
                .preferredColorScheme(.dark)
        }
    }
}
