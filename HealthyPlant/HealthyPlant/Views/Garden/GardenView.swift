import SwiftUI

// MARK: - Community Tab (standalone tab wrapping CommunityBrowseView)

struct CommunityTabView: View {
    var isVisible: Bool = true
    @StateObject private var viewModel = CommunityViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                CommunityBrowseView(viewModel: viewModel)
            }
            .navigationTitle("Community")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: CommunityPlant.self) { plant in
                CommunityPlantDetailView(plant: plant, viewModel: viewModel)
            }
        }
        .tint(Theme.accent)
    }
}

// MARK: - Garden Plant Card (shared component used in Profiles garden view)

struct GardenPlantCard: View {
    let plant: PlantProfile
    @State private var swaying = false

    private var plantEmoji: String {
        let t = plant.plantType.lowercased()
        if t.contains("tomato") { return "🍅" }
        if t.contains("sunflower") { return "🌻" }
        if t.contains("rose") { return "🌹" }
        if t.contains("strawberry") { return "🍓" }
        if t.contains("pepper") { return "🌶️" }
        if t.contains("lemon") || t.contains("citrus") { return "🍋" }
        if t.contains("mushroom") { return "🍄" }
        if t.contains("carrot") { return "🥕" }
        if t.contains("lettuce") || t.contains("salad") { return "🥬" }
        if t.contains("cactus") { return "🌵" }
        if t.contains("succulent") { return "🪴" }
        if t.contains("palm") { return "🌴" }
        if t.contains("tree") { return "🌳" }
        if t.contains("flower") { return "🌸" }
        if t.contains("basil") || t.contains("herb") || t.contains("fern") { return "🌿" }
        return "🌱"
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(plant.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)

            // Animated plant
            Text(plantEmoji)
                .font(.system(size: 60))
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

            // Care info
            VStack(alignment: .leading, spacing: 4) {
                careInfoRow(icon: "drop.fill", color: .blue, text: plant.waterNeeds)
                careInfoRow(icon: "sun.max.fill", color: .yellow, text: plant.sunNeeds)
                careInfoRow(icon: "clock.fill", color: .orange, text: plant.harvestTime)
            }
            .padding(.horizontal, 8)

            Text(plant.formattedHeight)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.vertical, 10)
        .frame(width: 160, height: 300)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
        .greenOutline(cornerRadius: 20)
    }

    private func careInfoRow(icon: String, color: Color, text: String?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(color)

            Text(text ?? "---")
                .font(.system(size: 9))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    CommunityTabView()
        .environmentObject(AppState())
        .environmentObject(AuthService())
}
