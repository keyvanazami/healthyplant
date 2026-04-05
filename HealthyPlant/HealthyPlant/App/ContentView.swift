import SwiftUI

// MARK: - Tab Enum

enum AppTab: String, CaseIterable {
    case home = "Home"
    case profiles = "Profiles"
    case scan = "Scan"
    case community = "Community"
    case calendar = "Calendar"
    case assistant = "Assistant"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .profiles: return "leaf.fill"
        case .scan: return "camera.fill"
        case .community: return "person.3.fill"
        case .calendar: return "calendar"
        case .assistant: return "message.fill"
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab: AppTab = .home
    @State private var onboardingComplete = UserDefaults.standard.bool(forKey: "hp_onboarding_complete")
    @State private var showSignInPrompt = false
    @State private var gardenerSetupComplete = UserDefaults.standard.bool(forKey: "hp_gardener_setup_complete")

    var body: some View {
        if !onboardingComplete {
            OnboardingView(isComplete: $onboardingComplete)
                .onChange(of: onboardingComplete) { _, done in
                    if done && !authService.isGoogleLinked {
                        showSignInPrompt = true
                    }
                }
        } else if showSignInPrompt {
            SignInPromptView(isPresented: $showSignInPrompt)
        } else if !gardenerSetupComplete {
            GardenerProfileSetupView(isComplete: $gardenerSetupComplete)
                .onChange(of: gardenerSetupComplete) { _, done in
                    if done {
                        UserDefaults.standard.set(true, forKey: "hp_gardener_setup_complete")
                    }
                }
        } else {
        ZStack(alignment: .bottom) {
            // Keep all tab views alive to prevent cancellation of in-flight requests
            HomeView(isVisible: selectedTab == .home)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(selectedTab == .home ? 1 : 0)
                .allowsHitTesting(selectedTab == .home)

            ProfilesListView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(selectedTab == .profiles ? 1 : 0)
                .allowsHitTesting(selectedTab == .profiles)

            PlantScanView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(selectedTab == .scan ? 1 : 0)
                .allowsHitTesting(selectedTab == .scan)

            CommunityTabView(isVisible: selectedTab == .community)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(selectedTab == .community ? 1 : 0)
                .allowsHitTesting(selectedTab == .community)

            CalendarView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(selectedTab == .calendar ? 1 : 0)
                .allowsHitTesting(selectedTab == .calendar)

            AssistantView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(selectedTab == .assistant ? 1 : 0)
                .allowsHitTesting(selectedTab == .assistant)

            // Custom tab bar
            TabBarView(selectedTab: $selectedTab)
        }
        .background(Theme.background)
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenCommunityTab"))) { _ in
            selectedTab = .community
        }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(AuthService())
}
