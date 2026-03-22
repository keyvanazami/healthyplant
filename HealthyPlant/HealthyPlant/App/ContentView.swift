import SwiftUI

// MARK: - Tab Enum

enum AppTab: String, CaseIterable {
    case home = "Home"
    case profiles = "Profiles"
    case garden = "Garden"
    case calendar = "Calendar"
    case assistant = "Assistant"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .profiles: return "leaf.fill"
        case .garden: return "tree.fill"
        case .calendar: return "calendar"
        case .assistant: return "message.fill"
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .profiles:
                    ProfilesListView()
                case .garden:
                    GardenView()
                case .calendar:
                    CalendarView()
                case .assistant:
                    AssistantView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            TabBarView(selectedTab: $selectedTab)
        }
        .background(Theme.background)
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(AuthService())
}
