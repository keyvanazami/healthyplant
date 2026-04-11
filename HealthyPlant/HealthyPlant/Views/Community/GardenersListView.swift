import SwiftUI

struct GardenersListView: View {
    @State private var gardeners: [GardenerProfile] = []
    @State private var isLoading = false
    private let service = GardenerService()

    var body: some View {
        Group {
            if isLoading && gardeners.isEmpty {
                ProgressView().tint(Theme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if gardeners.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textSecondary)
                    Text("No public gardeners yet")
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(gardeners, id: \.userId) { gardener in
                            NavigationLink {
                                PublicGardenerProfileView(
                                    userId: gardener.userId,
                                    displayName: gardener.displayName ?? "Gardener"
                                )
                            } label: {
                                gardenerRow(gardener)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .task {
            guard gardeners.isEmpty else { return }
            isLoading = true
            gardeners = (try? await service.fetchPublicGardeners()) ?? []
            isLoading = false
        }
    }

    private func gardenerRow(_ gardener: GardenerProfile) -> some View {
        HStack(spacing: 14) {
            // Avatar
            if let url = gardener.avatarURL, let parsed = URL(string: url) {
                AsyncImage(url: parsed) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    avatarPlaceholder(gardener)
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } else {
                avatarPlaceholder(gardener)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(gardener.displayName ?? "Gardener")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Theme.textPrimary)
                if let bio = gardener.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
                if let exp = gardener.experienceLevel {
                    HStack(spacing: 4) {
                        Image(systemName: exp.icon)
                            .font(.system(size: 9))
                        Text(exp.label)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Theme.accent.opacity(0.8))
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.caption2)
                Text("\(gardener.followerCount)")
                    .font(.caption)
            }
            .foregroundColor(Theme.textSecondary)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(Theme.textSecondary.opacity(0.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
        .contentShape(Rectangle())
    }

    private func avatarPlaceholder(_ gardener: GardenerProfile) -> some View {
        ZStack {
            Circle().fill(Theme.accent.opacity(0.15))
            Text(String(gardener.displayName?.prefix(1).uppercased() ?? "G"))
                .font(.title3.weight(.bold))
                .foregroundColor(Theme.accent)
        }
        .frame(width: 48, height: 48)
    }
}
