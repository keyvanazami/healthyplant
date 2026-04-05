import SwiftUI

enum ProfileViewMode { case booklet, grid, garden }

struct ProfilesListView: View {
    @StateObject private var viewModel = ProfilesViewModel()
    @StateObject private var gardenViewModel = GardenViewModel()
    @State private var showCreateProfile = false
    @State private var profileToDelete: PlantProfile? = nil
    @State private var showDeleteAlert = false
    @State private var viewMode: ProfileViewMode = .booklet

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if viewModel.isLoading && viewModel.profiles.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Theme.accent)
                        Text("Loading plants...")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                } else if viewModel.profiles.isEmpty && viewMode != .garden {
                    emptyState
                } else {
                    switch viewMode {
                    case .booklet:
                        ProfileBookletView(profiles: viewModel.profiles, viewModel: viewModel)
                    case .grid:
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.profiles) { profile in
                                    NavigationLink(value: profile) {
                                        ProfileCardView(profile: profile)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            profileToDelete = profile
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding()
                            .padding(.bottom, 100)
                        }
                    case .garden:
                        gardenContent
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    let rank = GardeningRank.compute(profiles: viewModel.profiles)
                    VStack(spacing: 1) {
                        Text("Profiles")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        HStack(spacing: 4) {
                            Image(systemName: rank.icon)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(rank.color)
                            Text(rank.name)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(rank.color)
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCreateProfile = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Theme.accent)
                            .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            switch viewMode {
                            case .booklet: viewMode = .grid
                            case .grid:    viewMode = .garden
                            case .garden:  viewMode = .booklet
                            }
                        }
                    } label: {
                        Image(systemName: viewMode == .booklet ? "square.grid.2x2"
                                        : viewMode == .grid    ? "tree.fill"
                                        :                        "book.fill")
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .navigationDestination(for: PlantProfile.self) { profile in
                ProfileDetailView(profile: profile, viewModel: viewModel)
            }
            .sheet(isPresented: $showCreateProfile, onDismiss: {
                Task { await viewModel.loadProfiles() }
            }) {
                CreateProfileView(viewModel: viewModel)
            }
            .alert("Delete Profile", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let profile = profileToDelete {
                        Task {
                            await viewModel.deleteProfile(id: profile.id)
                            await viewModel.loadProfiles()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    profileToDelete = nil
                }
            } message: {
                if let profile = profileToDelete {
                    Text("Are you sure you want to delete \"\(profile.name)\"? This action cannot be undone.")
                }
            }
            .task {
                await viewModel.loadProfiles()
            }
            .onChange(of: viewMode) { _, mode in
                if mode == .garden {
                    Task { await gardenViewModel.loadGarden() }
                }
            }
        }
        .tint(Theme.accent)
    }

    private var gardenContent: some View {
        Group {
            if gardenViewModel.isLoading && gardenViewModel.plants.isEmpty {
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
            } else if gardenViewModel.plants.isEmpty {
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
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(gardenViewModel.plants) { plant in
                            NavigationLink(value: plant) {
                                GardenPlantCard(plant: plant)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.accent.opacity(0.4))

            Text("No Plant Profiles")
                .font(.title2.bold())
                .foregroundColor(Theme.textPrimary)

            Text("Tap + to add your first plant")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
    }
}

// MARK: - Profile Card

struct ProfileCardView: View {
    let profile: PlantProfile

    var body: some View {
        VStack(spacing: 8) {
            // Photo or placeholder
            Group {
                if let urlString = profile.photoURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        plantPlaceholder
                    }
                } else {
                    plantPlaceholder
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(
                Circle().strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth)
            )

            Text(profile.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)

            Text(profile.plantType)
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .greenOutline(cornerRadius: 16)
    }

    private var plantPlaceholder: some View {
        ZStack {
            Circle().fill(Theme.accent.opacity(0.15))
            Image(systemName: "leaf.fill")
                .font(.system(size: 30))
                .foregroundColor(Theme.accent)
        }
    }
}

#Preview {
    ProfilesListView()
        .environmentObject(AppState())
        .environmentObject(AuthService())
}
