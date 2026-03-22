import SwiftUI

struct GardenView: View {
    @StateObject private var viewModel = GardenViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if viewModel.plants.isEmpty {
                    emptyState
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ForEach(viewModel.plants) { plant in
                                GardenPlantCard(plant: plant)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Garden")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await viewModel.loadGarden()
            }
        }
        .tint(Theme.accent)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tree.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.accent.opacity(0.4))

            Text("Your Garden is Empty")
                .font(.title2.bold())
                .foregroundColor(Theme.textPrimary)

            Text("Add plants in Profiles to see your garden")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Garden Plant Card

struct GardenPlantCard: View {
    let plant: PlantProfile
    @State private var swaying = false

    private var plantEmoji: String {
        switch plant.plantType.lowercased() {
        case let t where t.contains("tomato"): return "🍅"
        case let t where t.contains("basil"): return "🌿"
        case let t where t.contains("cactus"): return "🌵"
        case let t where t.contains("flower"): return "🌸"
        case let t where t.contains("sunflower"): return "🌻"
        case let t where t.contains("rose"): return "🌹"
        case let t where t.contains("tree"): return "🌳"
        default: return "🌱"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(plant.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)

            // Animated plant
            Text(plantEmoji)
                .font(.system(size: 70))
                .rotationEffect(.degrees(swaying ? 3 : -3), anchor: .bottom)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: swaying
                )
                .onAppear { swaying = true }

            // Pot
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.accent.opacity(0.2))
                .frame(width: 60, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth)
                )

            Text(plant.formattedHeight)
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(width: 140, height: 220)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
        .greenOutline(cornerRadius: 20)
    }
}

#Preview {
    GardenView()
        .environmentObject(AppState())
        .environmentObject(AuthService())
}
