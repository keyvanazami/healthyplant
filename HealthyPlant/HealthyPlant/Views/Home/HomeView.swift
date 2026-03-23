import SwiftUI

struct HomeView: View {
    @State private var showSettings = false
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Cactus image (static, composited on black to remove transparency)
                    Image("CactusImage")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 220)
                        .background(Theme.background)
                        .compositingGroup()

                    // Vase with "Healthy Plant" text
                    ZStack {
                        PotShape()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.accent.opacity(0.4),
                                        Theme.accent.opacity(0.15),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 120, height: 70)
                            .overlay(
                                PotShape()
                                    .strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth)
                            )

                        Text("Healthy Plant")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.accent)
                            .offset(y: 4)
                    }
                    .offset(y: -10)

                    Spacer().frame(height: 30)

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
