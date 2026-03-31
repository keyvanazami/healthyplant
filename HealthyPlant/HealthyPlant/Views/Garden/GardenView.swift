import SwiftUI

struct GardenView: View {
    var isVisible: Bool = true
    @StateObject private var viewModel = GardenViewModel()
    @StateObject private var profilesViewModel = ProfilesViewModel()
    @StateObject private var communityViewModel = CommunityViewModel()
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segmented control
                    Picker("", selection: $selectedSegment) {
                        Text("My Garden").tag(0)
                        Text("Community").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    if selectedSegment == 0 {
                        myGardenContent
                    } else {
                        CommunityBrowseView(viewModel: communityViewModel)
                    }
                }
            }
            .navigationTitle("Garden")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: PlantProfile.self) { profile in
                ProfileDetailView(profile: profile, viewModel: profilesViewModel)
            }
            .navigationDestination(for: CommunityPlant.self) { plant in
                CommunityPlantDetailView(plant: plant, viewModel: communityViewModel)
            }
            .task {
                await viewModel.loadGarden()
            }
            .task {
                await profilesViewModel.loadProfiles()
            }
            .onChange(of: isVisible) { _, visible in
                if visible {
                    Task {
                        await viewModel.loadGarden()
                        await profilesViewModel.loadProfiles()
                    }
                }
            }
        }
        .tint(Theme.accent)
    }

    private var myGardenContent: some View {
        Group {
            if viewModel.isLoading && viewModel.plants.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Theme.accent)
                    Text("Loading garden...")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
            } else if viewModel.plants.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(viewModel.plants) { plant in
                            NavigationLink(value: plant) {
                                GardenPlantCard(plant: plant)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
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
            Spacer()
        }
        .padding()
    }
}

// MARK: - Garden Plant Card

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
    GardenView()
        .environmentObject(AppState())
        .environmentObject(AuthService())
}
