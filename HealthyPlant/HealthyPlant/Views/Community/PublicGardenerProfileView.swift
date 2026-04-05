import SwiftUI

struct PublicGardenerProfileView: View {
    let userId: String
    let displayName: String

    @EnvironmentObject var authService: AuthService
    @State private var profile: GardenerProfile? = nil
    @State private var plants: [CommunityPlant] = []
    @State private var isLoading = true
    @State private var isPrivate = false
    @State private var isFollowInFlight = false
    @State private var showSignInAlert = false

    private let service = GardenerService()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(Theme.accent)
            } else if isPrivate {
                privateState
            } else if let profile {
                ScrollView {
                    VStack(spacing: 24) {
                        profileHeader(profile)
                        if !plants.isEmpty { plantsSection }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadAll() }
        .alert("Sign in to Follow", isPresented: $showSignInAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign in with Google") {
                Task { try? await authService.signInWithGoogle() }
            }
        } message: {
            Text("Create a free account to follow gardeners and get notified when they share new plants.")
        }
    }

    // MARK: - Profile header

    @ViewBuilder
    private func profileHeader(_ profile: GardenerProfile) -> some View {
        VStack(spacing: 16) {
            // Avatar
            Group {
                if let urlStr = profile.avatarURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Theme.accent.opacity(0.15))
                            .overlay(Image(systemName: "person.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Theme.accent))
                    }
                } else {
                    Circle().fill(Theme.accent.opacity(0.15))
                        .overlay(Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Theme.accent))
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth))

            // Name + experience
            VStack(spacing: 6) {
                Text(displayName)
                    .font(.title3.bold())
                    .foregroundColor(Theme.textPrimary)

                if let exp = profile.experienceLevel {
                    HStack(spacing: 4) {
                        Image(systemName: exp.icon)
                            .font(.caption)
                        Text(exp.label)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.accent.opacity(0.15))
                    .cornerRadius(8)
                }
            }

            // Bio
            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Stats + follow
            HStack(spacing: 28) {
                VStack(spacing: 2) {
                    Text("\(self.profile?.followerCount ?? profile.followerCount)")
                        .font(.headline.bold())
                        .foregroundColor(Theme.textPrimary)
                    Text("Followers")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Divider().frame(height: 32).background(Theme.accent.opacity(0.3))

                VStack(spacing: 2) {
                    Text("\(profile.followingCount)")
                        .font(.headline.bold())
                        .foregroundColor(Theme.textPrimary)
                    Text("Following")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Divider().frame(height: 32).background(Theme.accent.opacity(0.3))

                VStack(spacing: 2) {
                    Text("\(plants.count)")
                        .font(.headline.bold())
                        .foregroundColor(Theme.textPrimary)
                    Text("Plants")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.white.opacity(0.05))
            .cornerRadius(14)
            .greenOutline(cornerRadius: 14)

            // Follow button
            if userId != authService.userId {
                followButton(profile)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func followButton(_ profile: GardenerProfile) -> some View {
        let isFollowing = self.profile?.isFollowing ?? profile.isFollowing
        Button {
            Task { await toggleFollow() }
        } label: {
            HStack(spacing: 6) {
                if isFollowInFlight {
                    ProgressView().tint(isFollowing ? Theme.accent : .black)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isFollowing ? "person.badge.minus" : "person.badge.plus")
                    Text(isFollowing ? "Following" : "Follow")
                        .fontWeight(.semibold)
                }
            }
            .frame(minWidth: 140)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(isFollowing ? Color.clear : Theme.accent)
            .foregroundColor(isFollowing ? Theme.accent : .black)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Theme.accent, lineWidth: isFollowing ? 1.5 : 0)
            )
        }
        .disabled(isFollowInFlight)
    }

    // MARK: - Plants section

    private var plantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared Plants")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, 20)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(plants) { plant in
                    NavigationLink(value: plant) {
                        GardenerPlantCard(plant: plant)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Private state

    private var privateState: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundColor(Theme.accent.opacity(0.4))
            Text("This gardener's profile is private")
                .font(.title3.bold())
                .foregroundColor(Theme.textPrimary)
            Text("Only public profiles can be viewed in the community.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadAll() async {
        do {
            async let profileFetch = service.fetchProfile(userId: userId)
            async let plantsFetch = service.fetchGardenerPlants(userId: userId)
            profile = try await profileFetch
            plants = (try? await plantsFetch) ?? []
        } catch GardenerServiceError.notFound {
            isPrivate = true
        } catch {}
        isLoading = false
    }

    private func toggleFollow() async {
        guard !isFollowInFlight else { return }
        let isCurrentlyFollowing = profile?.isFollowing ?? false

        // Anonymous user guard
        if !isCurrentlyFollowing && !authService.isGoogleLinked {
            showSignInAlert = true
            return
        }

        isFollowInFlight = true
        defer { isFollowInFlight = false }
        do {
            if isCurrentlyFollowing {
                try await service.unfollowGardener(userId: userId)
                profile?.isFollowing = false
                profile?.followerCount = max(0, (profile?.followerCount ?? 1) - 1)
            } else {
                let response = try await service.followGardener(userId: userId)
                profile?.isFollowing = true
                profile?.followerCount = response.followerCount
            }
        } catch {
            // Revert on failure
        }
    }
}

// MARK: - Community Plant Card (used in public gardener view)

struct GardenerPlantCard: View {
    let plant: CommunityPlant

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let urlStr = plant.photoURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Theme.accent.opacity(0.1))
                }
                .frame(height: 120)
                .clipped()
            } else {
                Rectangle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.accent.opacity(0.4))
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(plant.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(plant.plantType)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .greenOutline(cornerRadius: 12)
    }
}

#Preview {
    NavigationStack {
        PublicGardenerProfileView(userId: "preview", displayName: "Jane Grower")
            .environmentObject(AuthService())
    }
}
