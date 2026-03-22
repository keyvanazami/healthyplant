import SwiftUI

struct HomeView: View {
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    CactusAnimationView()

                    Text("Healthy Plant")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Theme.accent)

                    Text("Your AI-powered gardening companion")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)

                    Spacer()
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        ZStack {
                            Circle()
                                .strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth)
                                .frame(width: 36, height: 36)

                            Image(systemName: "gearshape")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.accent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
